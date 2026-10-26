import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/monitoring/crash_reporter.dart';
import 'package:logistics_app/core/monitoring/crashlytics_failure_reporter.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';

import 'fake_crash_reporter.dart';

class _ThrowingReporter extends FakeCrashReporter {
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => throw StateError('plugin roto');
}

final _failure = OutboxFailure(
  id: '01HZX3K9V8Q2M4N6P8R0T2V4W6',
  queue: OutboxQueueType.action,
  kind: 'recordLoadScan',
  reason: OutboxFailureReason.rejected,
  status: 422,
  problemCode: 'unit_already_loaded',
  attempts: 3,
  occurredAt: DateTime.utc(2026, 10, 16),
);

void main() {
  test('registra un non-fatal agrupado por cola/kind/motivo/status', () async {
    final reporter = FakeCrashReporter();
    final FailureReporter failures = CrashlyticsFailureReporter(reporter);

    await failures.report(_failure);

    final error = reporter.errors.single;
    expect(error.fatal, isFalse);
    expect(error.reason, 'outbox:action:recordLoadScan:rejected:422');
    expect((error.error as OutboxFailureException).failure, same(_failure));
    expect(
      reporter.breadcrumbs.single,
      'outbox.failed action recordloadscan rejected',
    );
  });

  test('sin status (falla local) usa "-" en el agrupamiento', () {
    final local = OutboxFailure(
      id: 'x',
      queue: OutboxQueueType.photo,
      kind: 'pod',
      reason: OutboxFailureReason.invalidPayload,
      attempts: 1,
      occurredAt: DateTime.utc(2026),
    );
    expect(
      CrashlyticsFailureReporter.reasonFor(local),
      'outbox:photo:pod:invalidPayload:-',
    );
  });

  test('nunca lanza aunque el reporter falle', () async {
    final failures = CrashlyticsFailureReporter(_ThrowingReporter());
    await expectLater(failures.report(_failure), completes);
  });

  test('override del provider conecta con el crash reporter', () async {
    final reporter = FakeCrashReporter();
    final container = ProviderContainer(
      overrides: [
        crashReporterProvider.overrideWithValue(reporter),
        failureReporterProvider.overrideWith(
          (ref) => CrashlyticsFailureReporter(ref.watch(crashReporterProvider)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await reportSafely(container.read(failureReporterProvider), _failure);
    expect(reporter.errors, hasLength(1));
  });
}
