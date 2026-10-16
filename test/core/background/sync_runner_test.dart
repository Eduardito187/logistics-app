import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/background/sync_runner.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';
import 'package:logistics_app/core/network/auth_headers.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';

import '../auth/test_fakes.dart';
import '../offline/offline_test_fakes.dart';

// Drenado fuera de la UI (tarea de fondo) y al arrancar la app.

void main() {
  late AppDatabase db;
  late Directory tmp;
  late FakeSecureStorage storage;
  late ScriptedExecution exec;
  late CountingScheduler scheduler;
  String? tokenSeenByApi;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('bg_sync_test_');
    storage = FakeSecureStorage();
    exec = ScriptedExecution();
    scheduler = CountingScheduler();
    tokenSeenByApi = null;
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      appDatabaseProvider.overrideWithValue(db),
      logisticsApiProvider.overrideWith((ref) {
        tokenSeenByApi = ref.read(authHeadersProvider).bearerToken;
        return FakeSyncApi(exec);
      }),
      failureReporterProvider.overrideWithValue(RecordingReporter()),
      syncSchedulerProvider.overrideWithValue(scheduler),
      pendingPhotosDirectoryProvider.overrideWithValue(() async => tmp),
    ],
  );

  Future<void> seedPending(String id) => db.enqueue(
    OutboxActionsCompanion.insert(
      id: id,
      kind: 'recordLoadScan',
      payload:
          '{"shipment_id":"s1","unit_id":"u1","lat":0,"lng":0,'
          '"occurred_at":"2026-10-15T12:00:00.000Z"}',
      occurredAt: DateTime.utc(2026, 10, 15),
    ),
  );

  Future<int> pending() => db.countPendingActions();

  group('runBackgroundSync', () {
    test('con token guardado: pone el Bearer, drena y no queda nada', () async {
      storage.seed('app_bearer_token', 'tok-bg');
      await seedPending('A');
      final left = await runBackgroundSync(createContainer: makeContainer);
      expect(left, isFalse);
      expect(await pending(), 0);
      expect(tokenSeenByApi, 'tok-bg');
    });

    test(
      'sin token (sesión cerrada): no sube nada y conserva pendientes',
      () async {
        await seedPending('A');
        final left = await runBackgroundSync(createContainer: makeContainer);
        expect(left, isTrue);
        expect(exec.calls, 0);
        expect(await pending(), 1);
      },
    );

    test('sin red: devuelve true (la tarea única pide reintento)', () async {
      storage.seed('app_bearer_token', 'tok-bg');
      await seedPending('A');
      exec.enqueue([connectionError()]);
      expect(await runBackgroundSync(createContainer: makeContainer), isTrue);
      expect(await pending(), 1);
    });

    test('purga failed viejos aunque no haya sesión', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      await db.enqueue(
        OutboxActionsCompanion.insert(
          id: 'F',
          kind: 'recordLoadScan',
          payload: '{}',
          occurredAt: old,
          status: const Value('failed'),
          createdAt: Value(old),
        ),
      );
      await runBackgroundSync(createContainer: makeContainer);
      expect(await db.select(db.outboxActions).get(), isEmpty);
    });

    test('un error inesperado no lanza: devuelve true', () async {
      final left = await runBackgroundSync(
        createContainer: () => ProviderContainer(
          overrides: [
            tokenStoreProvider.overrideWith((ref) => throw StateError('roto')),
          ],
        ),
      );
      expect(left, isTrue);
    });
  });

  group('drainOnStartup', () {
    late ProviderContainer container;

    setUp(() {
      container = makeContainer();
    });

    tearDown(() => container.dispose());

    void login() =>
        container.read(authHeadersProvider.notifier).setToken('tok-main');

    test('con sesión, red y pendientes: drena', () async {
      login();
      await seedPending('A');
      await drainOnStartup(container, isOnline: () async => true);
      expect(await pending(), 0);
      expect(tokenSeenByApi, 'tok-main');
    });

    test('sin red: no llama al API y programa la tarea de fondo', () async {
      login();
      await seedPending('A');
      await drainOnStartup(container, isOnline: () async => false);
      expect(exec.calls, 0);
      expect(scheduler.oneOffs, 1);
      expect(await pending(), 1);
    });

    test('sin pendientes: ni consulta la red', () async {
      login();
      var asked = false;
      await drainOnStartup(
        container,
        isOnline: () async {
          asked = true;
          return true;
        },
      );
      expect(asked, isFalse);
      expect(exec.calls, 0);
    });

    test('sin sesión: no drena (espera al login)', () async {
      await seedPending('A');
      await drainOnStartup(container, isOnline: () async => true);
      expect(exec.calls, 0);
      expect(await pending(), 1);
    });

    test('nunca lanza aunque falle la consulta de red', () async {
      login();
      await seedPending('A');
      await drainOnStartup(
        container,
        isOnline: () async => throw StateError('sin plugin'),
      );
      expect(await pending(), 1);
    });
  });
}
