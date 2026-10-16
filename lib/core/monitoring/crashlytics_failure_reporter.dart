import '../offline/failure_reporter.dart';
import 'crash_reporter.dart';

/// Escritura offline que no llegó al backend, como excepción no fatal para
/// Crashlytics. Solo lleva los metadatos técnicos de [OutboxFailure] (sin
/// payload, sin `detail` del backend, sin datos del usuario).
class OutboxFailureException implements Exception {
  const OutboxFailureException(this.failure);

  final OutboxFailure failure;

  @override
  String toString() => failure.toString();
}

/// [FailureReporter] de la cola offline sobre el [CrashReporter]: cada acción
/// rechazada o agotada queda como non-fatal en Crashlytics, agrupada por
/// cola/kind/motivo/status para ver qué flujos pierden datos en terreno.
///
/// Override en el `ProviderContainer` de `main.dart`:
/// `failureReporterProvider.overrideWith((ref) =>
///     CrashlyticsFailureReporter(ref.watch(crashReporterProvider)))`.
class CrashlyticsFailureReporter implements FailureReporter {
  const CrashlyticsFailureReporter(this._reporter);

  final CrashReporter _reporter;

  /// Clave de agrupamiento estable (sin ids): `outbox:action:recordLoadScan:rejected:422`.
  static String reasonFor(OutboxFailure f) =>
      'outbox:${f.queue.name}:${f.kind}:${f.reason.name}:${f.status ?? '-'}';

  @override
  Future<void> report(OutboxFailure failure) async {
    try {
      _reporter.breadcrumb(
        'outbox.failed ${failure.queue.name} ${failure.kind} '
        '${failure.reason.name}',
      );
      await _reporter.recordError(
        OutboxFailureException(failure),
        StackTrace.current,
        reason: reasonFor(failure),
      );
    } on Object {
      // Contrato: nunca lanzar ni trabar el drenado de la cola.
    }
  }
}
