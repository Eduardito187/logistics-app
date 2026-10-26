import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/sync_retry_policy.dart';

ApiException _status(int s, {bool connection = false}) =>
    ApiException(status: s, title: 't', isConnectionError: connection);

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
