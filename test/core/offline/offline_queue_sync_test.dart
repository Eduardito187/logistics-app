import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/sync_retry_policy.dart';

import 'offline_test_fakes.dart';

// Rechazos visibles para soporte (FailureReporter), reintentos con backoff
// sobre `attempts`, tope de reintentos y 401 sin perder la fila.

void main() {
  late AppDatabase db;
  late ScriptedExecution exec;
  late RecordingReporter reporter;
  late CountingScheduler scheduler;
  late ProviderContainer container;
  late OfflineQueue queue;

  void build(List<Object?> script) {
    exec = ScriptedExecution(script.cast());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        logisticsApiProvider.overrideWithValue(FakeSyncApi(exec)),
        failureReporterProvider.overrideWithValue(reporter),
        syncSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    queue = container.read(offlineQueueProvider);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reporter = RecordingReporter();
    scheduler = CountingScheduler();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<OutboxAction>> rows() => db.select(db.outboxActions).get();

  Future<SubmitOutcome> submit({String? key}) => queue.submit(
    kind: 'recordLoadScan',
    payload: scanPayload(),
    label: 'Carga',
    idempotencyKey: key,
  );

  Future<void> seedPending(String id, {int attempts = 0, String? payload}) =>
      db.enqueue(
        OutboxActionsCompanion.insert(
          id: id,
          kind: 'recordLoadScan',
          payload:
              payload ??
              '{"shipment_id":"s1","unit_id":"u1","lat":0,'
                  '"lng":0,"occurred_at":"2026-10-15T12:00:00.000Z"}',
          occurredAt: DateTime.utc(2026, 10, 15),
          attempts: Value(attempts),
        ),
      );

  group('submit: rechazo permanente se reporta', () {
    test(
      '422 → failed y un evento rejected con status y code, sin detail',
      () async {
        build([httpError(422, problemCode: 'bad_request')]);
        final outcome = await submit(key: 'K1');
        expect(outcome, SubmitOutcome.failed);
        expect(reporter.events, hasLength(1));
        final e = reporter.events.single;
        expect(e.id, 'K1');
        expect(e.queue, OutboxQueueType.action);
        expect(e.kind, 'recordLoadScan');
        expect(e.reason, OutboxFailureReason.rejected);
        expect(e.status, 422);
        expect(e.problemCode, 'bad_request');
        expect(e.attempts, 1);
        // Sin datos personales: el detail del backend no viaja en el evento.
        expect(e.toJson().toString(), isNot(contains('Juan')));
      },
    );

    test('un reporter que lanza no rompe submit', () async {
      reporter.throwOnReport = true;
      build([httpError(400)]);
      expect(await submit(), SubmitOutcome.failed);
    });

    test('éxito no reporta nada', () async {
      build([]);
      expect(await submit(), SubmitOutcome.sent);
      expect(reporter.events, isEmpty);
    });
  });

  group('submit: transitorios', () {
    test('401 → queued, la fila sigue pending y no se reporta', () async {
      build([httpError(401)]);
      expect(await submit(), SubmitOutcome.queued);
      final r = (await rows()).single;
      expect(r.status, 'pending');
      expect(r.attempts, 0);
      expect(reporter.events, isEmpty);
    });

    test('sin red → queued, no suma intento, pide tarea de fondo', () async {
      build([connectionError()]);
      expect(await submit(), SubmitOutcome.queued);
      expect((await rows()).single.attempts, 0);
      expect(scheduler.oneOffs, 1);
      expect(offlineQueueHasScheduledRetry(queue), isFalse);
    });

    test(
      '503 → queued, suma intento y programa reintento con backoff',
      () async {
        build([httpError(503)]);
        expect(await submit(), SubmitOutcome.queued);
        final r = (await rows()).single;
        expect(r.status, 'pending');
        expect(r.attempts, 1);
        expect(r.lastError, isNotNull);
        expect(offlineQueueHasScheduledRetry(queue), isTrue);
        expect(scheduler.oneOffs, 1);
      },
    );

    test('dispose cancela el reintento programado', () async {
      build([httpError(429)]);
      await submit();
      expect(offlineQueueHasScheduledRetry(queue), isTrue);
      disposeOfflineQueue(queue);
      expect(offlineQueueHasScheduledRetry(queue), isFalse);
    });
  });

  group('drain', () {
    test('5xx suma attempts, corta y deja pending', () async {
      await seedPending('A', attempts: 2);
      await seedPending('B');
      build([httpError(500)]);
      await queue.drain();
      final byId = {for (final r in await rows()) r.id: r};
      expect(byId['A']!.status, 'pending');
      expect(byId['A']!.attempts, 3);
      expect(byId['B']!.attempts, 0, reason: 'el drenado se cortó en A');
      expect(exec.calls, 1);
      expect(offlineQueueHasScheduledRetry(queue), isTrue);
    });

    test(
      'al llegar al tope de 5xx pasa a failed (retries_exhausted) y sigue',
      () async {
        await seedPending('A', attempts: SyncRetryPolicy.maxServerAttempts - 1);
        await seedPending('B');
        build([httpError(503), null]);
        await queue.drain();
        final remaining = await rows();
        expect(remaining.single.id, 'A');
        expect(remaining.single.status, 'failed');
        expect(remaining.single.attempts, SyncRetryPolicy.maxServerAttempts);
        final e = reporter.events.single;
        expect(e.reason, OutboxFailureReason.retriesExhausted);
        expect(e.status, 503);
        expect(e.attempts, SyncRetryPolicy.maxServerAttempts);
      },
    );

    test('401 corta sin marcar failed ni sumar intentos', () async {
      await seedPending('A');
      await seedPending('B');
      build([httpError(401)]);
      await queue.drain();
      final all = await rows();
      expect(all.map((r) => r.status), everyElement('pending'));
      expect(all.map((r) => r.attempts), everyElement(0));
      expect(reporter.events, isEmpty);
    });

    test('4xx en drain se reporta como rejected', () async {
      await seedPending('A');
      build([httpError(409)]);
      await queue.drain();
      expect((await rows()).single.status, 'failed');
      expect(reporter.events.single.reason, OutboxFailureReason.rejected);
      expect(reporter.events.single.status, 409);
    });

    test('payload corrupto se reporta como invalid_payload', () async {
      await seedPending('A', payload: '{no-json');
      build([]);
      await queue.drain();
      expect(reporter.events.single.reason, OutboxFailureReason.invalidPayload);
      expect(reporter.events.single.status, isNull);
    });

    test('kind desconocido se reporta como unknown_kind', () async {
      await db.enqueue(
        OutboxActionsCompanion.insert(
          id: 'Z',
          kind: 'kindQueYaNoExiste',
          payload: '{}',
          occurredAt: DateTime.utc(2026),
        ),
      );
      build([]);
      await queue.drain();
      expect(reporter.events.single.reason, OutboxFailureReason.unknownKind);
      expect(reporter.events.single.kind, 'kindQueYaNoExiste');
    });
  });

  test('retryFailed reinicia attempts para no fallar al primer 5xx', () async {
    await seedPending('A', attempts: SyncRetryPolicy.maxServerAttempts);
    await db.markFailed('A', 'x');
    build([httpError(503)]);
    await queue.retryFailed('A');
    final r = (await rows()).single;
    expect(r.status, 'pending');
    expect(r.attempts, 1);
  });
}
