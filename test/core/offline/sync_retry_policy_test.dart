import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/sync_retry_policy.dart';

ApiException _status(int s, {bool connection = false, Duration? retryAfter}) =>
    ApiException(
      status: s,
      title: 't',
      isConnectionError: connection,
      retryAfter: retryAfter,
    );

void main() {
  group('SyncRetryPolicy.isTransient', () {
    test('sin red, 401, 429 y 5xx son transitorios', () {
      expect(SyncRetryPolicy.isTransient(_status(0, connection: true)), isTrue);
      expect(SyncRetryPolicy.isTransient(_status(401)), isTrue);
      expect(SyncRetryPolicy.isTransient(_status(429)), isTrue);
      expect(SyncRetryPolicy.isTransient(_status(500)), isTrue);
      expect(SyncRetryPolicy.isTransient(_status(503)), isTrue);
    });

    test('el resto de 4xx es permanente', () {
      for (final s in [400, 403, 404, 409, 422]) {
        expect(SyncRetryPolicy.isTransient(_status(s)), isFalse, reason: '$s');
      }
    });
  });

  test('solo 429/5xx suman intentos', () {
    expect(SyncRetryPolicy.countsAsAttempt(_status(429)), isTrue);
    expect(SyncRetryPolicy.countsAsAttempt(_status(502)), isTrue);
    expect(
      SyncRetryPolicy.countsAsAttempt(_status(0, connection: true)),
      isFalse,
    );
    expect(SyncRetryPolicy.countsAsAttempt(_status(401)), isFalse);
  });

  test('backoff exponencial con techo', () {
    expect(SyncRetryPolicy.backoffFor(0), const Duration(seconds: 5));
    expect(SyncRetryPolicy.backoffFor(1), const Duration(seconds: 10));
    expect(SyncRetryPolicy.backoffFor(3), const Duration(seconds: 40));
    expect(SyncRetryPolicy.backoffFor(50), SyncRetryPolicy.backoffMax);
    expect(SyncRetryPolicy.backoffFor(-3), const Duration(seconds: 5));
  });

  group('SyncRetryPolicy.retryAfterOf', () {
    test('solo se aprovecha en 429 y 503', () {
      const espera = Duration(seconds: 90);
      expect(
        SyncRetryPolicy.retryAfterOf(_status(429, retryAfter: espera)),
        espera,
      );
      expect(
        SyncRetryPolicy.retryAfterOf(_status(503, retryAfter: espera)),
        espera,
      );
      // En otros estados la cabecera no significa "esperá tanto".
      expect(
        SyncRetryPolicy.retryAfterOf(_status(500, retryAfter: espera)),
        isNull,
      );
      expect(
        SyncRetryPolicy.retryAfterOf(_status(404, retryAfter: espera)),
        isNull,
      );
    });

    test('sin cabecera devuelve null', () {
      expect(SyncRetryPolicy.retryAfterOf(_status(429)), isNull);
    });
  });

  group('SyncRetryPolicy.delayFor', () {
    test('sin Retry-After manda el backoff', () {
      expect(SyncRetryPolicy.delayFor(0), const Duration(seconds: 5));
      expect(
        SyncRetryPolicy.delayFor(2, retryAfter: null),
        const Duration(seconds: 20),
      );
    });

    test('con Retry-After mayor que el backoff, gana el servidor', () {
      expect(
        SyncRetryPolicy.delayFor(0, retryAfter: const Duration(seconds: 120)),
        const Duration(seconds: 120),
      );
    });

    test('con Retry-After menor que el backoff, gana el backoff', () {
      // El servidor pide 1 s pero ya van 4 intentos (80 s): no se martilla.
      expect(
        SyncRetryPolicy.delayFor(4, retryAfter: const Duration(seconds: 1)),
        const Duration(seconds: 80),
      );
    });

    test('un Retry-After enorme se recorta al tope', () {
      expect(
        SyncRetryPolicy.delayFor(0, retryAfter: const Duration(hours: 6)),
        SyncRetryPolicy.retryAfterMax,
      );
    });

    test('un Retry-After no positivo se ignora', () {
      expect(
        SyncRetryPolicy.delayFor(1, retryAfter: Duration.zero),
        const Duration(seconds: 10),
      );
      expect(
        SyncRetryPolicy.delayFor(1, retryAfter: const Duration(seconds: -5)),
        const Duration(seconds: 10),
      );
    });
  });

  group('OutboxFailure.toJson', () {
    test('snake_case, sin datos personales y con fecha UTC', () {
      final json = OutboxFailure(
        id: '01J',
        queue: OutboxQueueType.action,
        kind: 'recordLoadScan',
        reason: OutboxFailureReason.retriesExhausted,
        status: 503,
        problemCode: null,
        attempts: 50,
        occurredAt: DateTime.utc(2026, 10, 16, 10),
      ).toJson();
      expect(json, {
        'id': '01J',
        'queue': 'action',
        'kind': 'recordLoadScan',
        'reason': 'retries_exhausted',
        'status': 503,
        'problem_code': null,
        'attempts': 50,
        'occurred_at': '2026-10-16T10:00:00.000Z',
      });
    });

    test('el reporter por defecto es no-op', () async {
      await const NoopFailureReporter().report(
        OutboxFailure(
          id: 'x',
          queue: OutboxQueueType.photo,
          kind: 'pod',
          reason: OutboxFailureReason.rejected,
          attempts: 1,
          occurredAt: DateTime(2026),
        ),
      );
    });
  });
}
