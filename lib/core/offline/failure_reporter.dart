import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cola local donde ocurrió la falla.
enum OutboxQueueType {
  /// Acción JSON de `outbox_actions` (escaneos, POD, incidentes...).
  action,

  /// Foto de evidencia de `pending_photos`.
  photo,
}

/// Por qué una escritura de terreno quedó `failed` en el teléfono.
enum OutboxFailureReason {
  /// El backend la rechazó con un 4xx no transitorio (datos, permiso, estado).
  rejected,

  /// Se agotó el tope de reintentos transitorios (429/5xx persistentes).
  retriesExhausted,

  /// El payload local no se pudo decodificar (fila corrupta).
  invalidPayload,

  /// El `kind` ya no existe en el dispatcher (p. ej. tras actualizar la app).
  unknownKind,
}

/// Evento de una escritura offline que NO llegó al backend.
///
/// Sin datos personales a propósito: no lleva payload, ni el `detail` del
/// backend (puede citar datos del cliente), ni nombre de usuario. Solo lo
/// necesario para que la torre de control/soporte detecte y correlacione:
/// tipo de acción, estado HTTP, código RFC 7807 estable e intentos. El `id` es
/// el ULID de la `Idempotency-Key` (no es dato personal) y permite cruzarlo con
/// los logs del backend.
class OutboxFailure {
  const OutboxFailure({
    required this.id,
    required this.queue,
    required this.kind,
    required this.reason,
    required this.attempts,
    required this.occurredAt,
    this.status,
    this.problemCode,
  });

  /// ULID / Idempotency-Key de la acción (o id local de la foto).
  final String id;
  final OutboxQueueType queue;

  /// `kind` de la acción (p. ej. `recordLoadScan`) o `pod`/`damage` en fotos.
  final String kind;
  final OutboxFailureReason reason;

  /// Código HTTP de la respuesta; `null` si la falla fue local.
  final int? status;

  /// `code` RFC 7807 del backend (`ProblemCode.json`), si vino.
  final String? problemCode;

  /// Intentos acumulados (incluido el que falló).
  final int attempts;

  /// Momento del hecho en terreno (o del encolado en fotos).
  final DateTime occurredAt;

  /// Forma JSON (snake_case) que propone `POST /app/outbox-failures`.
  Map<String, Object?> toJson() => {
    'id': id,
    'queue': queue.name,
    'kind': kind,
    'reason': switch (reason) {
      OutboxFailureReason.rejected => 'rejected',
      OutboxFailureReason.retriesExhausted => 'retries_exhausted',
      OutboxFailureReason.invalidPayload => 'invalid_payload',
      OutboxFailureReason.unknownKind => 'unknown_kind',
    },
    'status': status,
    'problem_code': problemCode,
    'attempts': attempts,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
  };

  @override
  String toString() =>
      'OutboxFailure(${queue.name}/$kind, ${reason.name}, status: $status, '
      'code: $problemCode, attempts: $attempts)';
}

/// Destino de los rechazos de la cola offline.
///
/// Con el offline invisible el usuario de campo no ve que una acción quedó
/// `failed`; este reporter es el canal para que alguien se entere. La
/// implementación real (Crashlytics, y a futuro `POST /app/outbox-failures`)
/// la conecta otra capa sobreescribiendo [failureReporterProvider].
///
/// Contrato: `report` nunca debe lanzar ni bloquear el drenado; la cola igual
/// lo envuelve en try/catch.
abstract interface class FailureReporter {
  Future<void> report(OutboxFailure failure);
}

/// Implementación por defecto: no hace nada.
class NoopFailureReporter implements FailureReporter {
  const NoopFailureReporter();

  @override
  Future<void> report(OutboxFailure failure) async {}
}

/// Reporter de rechazos de la cola offline. Por defecto no-op; se sobreescribe
/// (override en el `ProviderContainer`) para conectarlo a Crashlytics.
final failureReporterProvider = Provider<FailureReporter>(
  (ref) => const NoopFailureReporter(),
);

/// Reporta sin dejar que una falla del reporter afecte a la cola.
Future<void> reportSafely(FailureReporter reporter, OutboxFailure f) async {
  try {
    await reporter.report(f);
  } on Object {
    // Best-effort: perder un reporte no puede trabar la sincronización.
  }
}
