import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ulid/ulid.dart';

import '../api/logistics_api.dart';
import '../background/sync_scheduler.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'app_database.dart';
import 'failure_reporter.dart';
import 'offline_dispatcher.dart';
import 'submit_outcome.dart';
import 'sync_retry_policy.dart';

// Se reexportan las piezas movidas por SRP ([SubmitOutcome] y
// [ConnectivityNotifier]) para no romper a quienes importan
// `offline/offline_queue.dart`.
export 'connectivity_notifier.dart';
export 'submit_outcome.dart';

/// Una acción de escritura reconstruible desde la cola: toma el cliente API y el
/// payload JSON y ejecuta la llamada real. El dispatcher central mapea cada
/// `kind` a uno de estos.
typedef OfflineActionHandler =
    Future<void> Function(
      LogisticsApi api,
      String idempotencyKey,
      Map<String, Object?> payload,
    );

/// Servicio offline-first. Todas las escrituras de terreno pasan por acá.
///
/// `submit` intenta la llamada de inmediato; si no hay red, encola con el mismo
/// `id`/`Idempotency-Key` para reintentar al recuperar señal. Nunca bloquea al
/// usuario esperando al servidor.
class OfflineQueue {
  OfflineQueue(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

  /// Encola y/o envía una acción de escritura.
  ///
  /// [kind] debe existir en `offlineHandlers`. [payload] es el cuerpo de la
  /// request serializable a JSON. [label] es texto legible para la UI de sync.
  Future<SubmitOutcome> submit({
    required String kind,
    required Map<String, Object?> payload,
    required String label,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    // El `kind` debe existir en el dispatcher. Se valida ANTES de persistir: un
    // kind desconocido es un error de programación (no un dato de terreno) y
    // encolarlo dejaría una fila "envenenada" que luego rompería el drain.
    if (!offlineHandlers.containsKey(kind)) {
      throw StateError('Acción offline desconocida: $kind');
    }

    final id = idempotencyKey ?? Ulid().toString();
    final when = occurredAt ?? DateTime.now();
    final payloadWithKey = {...payload, 'idempotency_key': id};

    // Siempre se persiste primero: si la app muere tras el POST, el reintento
    // es idempotente y no duplica.
    await _db.enqueue(
      OutboxActionsCompanion.insert(
        id: id,
        kind: kind,
        payload: jsonEncode(payloadWithKey),
        occurredAt: when,
        label: Value(label),
      ),
    );

    try {
      await _run(id, kind, payloadWithKey);
      await _db.markSynced(id);
      return SubmitOutcome.sent;
    } on ApiException catch (e) {
      if (SyncRetryPolicy.isTransient(e)) {
        // Fallo transitorio (sin red, 401, 429 o 5xx): no es culpa del dato,
        // así que la fila queda pendiente para reintentar (reconexión, backoff
        // o tarea de fondo). Marcarla fallida perdería la escritura de terreno.
        if (SyncRetryPolicy.countsAsAttempt(e)) {
          await _db.markTransientFailure(id, e.message);
          _scheduleRetry(await _db.actionAttempts(id));
        }
        unawaited(_scheduler.scheduleOneOff());
        return SubmitOutcome.queued;
      }
      // Error de datos (4xx permanente): no sirve reintentar, se marca fallida
      // y se reporta (el usuario no ve la cola: offline invisible).
      await _db.markFailed(id, e.message);
      await _report(
        id: id,
        kind: kind,
        occurredAt: when,
        attempts: await _db.actionAttempts(id),
        reason: OutboxFailureReason.rejected,
        error: e,
      );
      return SubmitOutcome.failed;
    }
  }

  SyncScheduler get _scheduler => _ref.read(syncSchedulerProvider);

  /// Registra un rechazo en el [FailureReporter] (sin datos personales).
  Future<void> _report({
    required String id,
    required String kind,
    required DateTime occurredAt,
    required int attempts,
    required OutboxFailureReason reason,
    ApiException? error,
  }) {
    return reportSafely(
      _ref.read(failureReporterProvider),
      OutboxFailure(
        id: id,
        queue: OutboxQueueType.action,
        kind: kind,
        reason: reason,
        status: error == null || error.status == 0 ? null : error.status,
        problemCode: error?.code?.json,
        attempts: attempts,
        occurredAt: occurredAt,
      ),
    );
  }

  Future<void> _run(
    String id,
    String kind,
    Map<String, Object?> payload,
  ) async {
    final handler = offlineHandlers[kind];
    if (handler == null) {
      throw StateError('Acción offline desconocida: $kind');
    }
    final api = _ref.read(logisticsApiProvider);
    try {
      await handler(api, id, payload);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cantidad de acciones pendientes de subir (no incluye las fallidas).
  /// Usa `COUNT(*)`: no carga las filas ni sus payloads.
  Future<int> pendingCount() => _db.countPendingActions();

  /// Tamaño de lote del drenado: se leen de a [_drainBatchSize] filas (con su
  /// payload) en vez de toda la cola, para no cargar en memoria días de
  /// escaneos acumulados sin señal en un teléfono de 1 GB.
  static const int _drainBatchSize = 25;

  /// Drenado en curso; las llamadas concurrentes se suman a este.
  Future<void>? _drainInFlight;

  /// Otra llamada pidió drenar mientras había uno en curso: se repite una vez
  /// al terminar para no perder filas encoladas (o reactivadas) entretanto.
  bool _drainRequested = false;

  /// Reintenta todas las acciones pendientes. Se llama al recuperar señal.
  ///
  /// Procesa por lotes y nunca corre dos drenados a la vez (dos disparos
  /// seguidos de conectividad no reenvían la misma fila en paralelo).
  Future<void> drain() {
    final inFlight = _drainInFlight;
    if (inFlight != null) {
      _drainRequested = true;
      return inFlight;
    }
    final run = _drainLoop().whenComplete(() => _drainInFlight = null);
    _drainInFlight = run;
    return run;
  }

  Future<void> _drainLoop() async {
    do {
      _drainRequested = false;
      await _drainOnce();
    } while (_drainRequested);
  }

  Future<void> _drainOnce() async {
    while (true) {
      // Cada fila del lote se borra (enviada), pasa a `failed` o corta el
      // drenado (transitorio), así que el siguiente lote siempre avanza.
      final batch = await _db.pendingActions(limit: _drainBatchSize);
      for (final action in batch) {
        try {
          final payload = jsonDecode(action.payload) as Map<String, Object?>;
          await _run(action.id, action.kind, payload);
          await _db.markSynced(action.id);
        } on ApiException catch (e) {
          if (SyncRetryPolicy.isTransient(e)) {
            if (!SyncRetryPolicy.countsAsAttempt(e)) {
              // Sin red o 401: se corta el drenado y la fila queda pendiente;
              // la reconexión, el próximo login o la tarea de fondo reintentan.
              unawaited(_scheduler.scheduleOneOff());
              return;
            }
            final attempts = action.attempts + 1;
            if (attempts >= SyncRetryPolicy.maxServerAttempts) {
              // Tope de 429/5xx: se da por perdida, se aísla y se reporta.
              await _db.markFailed(action.id, e.message);
              await _reportRow(
                action,
                OutboxFailureReason.retriesExhausted,
                error: e,
              );
              continue;
            }
            // 429/5xx: suma el intento, corta y reintenta con backoff.
            await _db.markTransientFailure(action.id, e.message);
            _scheduleRetry(attempts);
            unawaited(_scheduler.scheduleOneOff());
            return;
          }
          await _db.markFailed(action.id, e.message);
          await _reportRow(action, OutboxFailureReason.rejected, error: e);
        } on StateError catch (e) {
          // `kind` obsoleto/desconocido (p. ej. tras actualizar la app y
          // remover un handler): se aísla ESTA fila y se sigue con el resto.
          await _db.markFailed(action.id, e.message);
          await _reportRow(action, OutboxFailureReason.unknownKind);
        } on FormatException catch (e) {
          // Payload corrupto: reintentarlo no lo arregla; se aísla la fila.
          await _db.markFailed(action.id, 'Payload inválido: ${e.message}');
          await _reportRow(action, OutboxFailureReason.invalidPayload);
        }
      }
      if (batch.length < _drainBatchSize) return;
    }
  }

  Future<void> _reportRow(
    OutboxAction action,
    OutboxFailureReason reason, {
    ApiException? error,
  }) => _report(
    id: action.id,
    kind: action.kind,
    occurredAt: action.occurredAt,
    // `markFailed` ya sumó el intento que falló.
    attempts: action.attempts + 1,
    reason: reason,
    error: error,
  );

  /// Reintento en primer plano con backoff exponencial sobre `attempts`
  /// (5 s, 10 s, 20 s... tope 10 min). Un solo timer a la vez.
  Timer? _retryTimer;
  bool _disposed = false;

  void _scheduleRetry(int attempts) {
    if (_disposed || (_retryTimer?.isActive ?? false)) return;
    _retryTimer = Timer(SyncRetryPolicy.backoffFor(attempts), () {
      _retryTimer = null;
      if (!_disposed) unawaited(drain());
    });
  }

  /// Cancela el reintento programado (al destruir el provider). Privado a
  /// propósito: los dobles de test que hacen `implements OfflineQueue` no
  /// tienen que implementarlo.
  void _dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> retryFailed(String id) async {
    await (_db.update(_db.outboxActions)..where((t) => t.id.equals(id))).write(
      // Reintento manual: se reinicia el contador para que una fila que agotó
      // el tope de 429/5xx no vuelva a fallar al primer error.
      const OutboxActionsCompanion(
        status: Value('pending'),
        attempts: Value(0),
      ),
    );
    await drain();
  }

  Stream<List<OutboxAction>> watchQueue() => _db.watchQueue();
}

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  final queue = OfflineQueue(ref, ref.watch(appDatabaseProvider));
  ref.onDispose(queue._dispose);
  return queue;
});

/// `true` si [queue] tiene un reintento con backoff programado. Función libre
/// (no miembro) para no ampliar la interfaz que implementan los dobles.
@visibleForTesting
bool offlineQueueHasScheduledRetry(OfflineQueue queue) =>
    queue._retryTimer?.isActive ?? false;

/// Simula la destrucción del provider (cancela el reintento programado).
@visibleForTesting
void disposeOfflineQueue(OfflineQueue queue) => queue._dispose();
