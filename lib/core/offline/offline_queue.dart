import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ulid/ulid.dart';

import '../api/logistics_api.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'app_database.dart';
import 'offline_dispatcher.dart';
import 'submit_outcome.dart';

// Se reexportan las piezas movidas por SRP ([SubmitOutcome] y
// [ConnectivityNotifier]) para no romper a quienes importan
// `offline/offline_queue.dart`.
export 'connectivity_notifier.dart';
export 'submit_outcome.dart';

/// Una acción de escritura reconstruible desde la cola: toma el cliente API y el
/// payload JSON y ejecuta la llamada real. El dispatcher central mapea cada
/// `kind` a uno de estos.
typedef OfflineActionHandler = Future<void> Function(
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
      if (_isTransient(e)) {
        // Fallo transitorio (sin red, 429 o 5xx): no es culpa del dato, así que
        // la fila queda pendiente para reintentar al recuperar señal. Marcarla
        // como fallida perdería la escritura de terreno (viola offline-first).
        return SubmitOutcome.queued;
      }
      // Error de datos (4xx permanente): no sirve reintentar, se marca fallida.
      await _db.markFailed(id, e.message);
      return SubmitOutcome.failed;
    }
  }

  /// Un error que NO es culpa del dato y conviene reintentar: sin conexión,
  /// rate limit (429) o error de servidor (5xx).
  static bool _isTransient(ApiException e) =>
      e.isConnectionError || e.isRateLimited || e.isServerError;

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

  /// Reintenta todas las acciones pendientes. Se llama al recuperar señal.
  Future<void> drain() async {
    final pending = await _db.pendingActions();
    for (final action in pending) {
      final payload = jsonDecode(action.payload) as Map<String, Object?>;
      try {
        await _run(action.id, action.kind, payload);
        await _db.markSynced(action.id);
      } on ApiException catch (e) {
        if (_isTransient(e)) {
          // Transitorio (sin red, 429 o 5xx): se corta el drenado y la fila
          // queda pendiente; se reintenta en el próximo ciclo.
          break;
        }
        await _db.markFailed(action.id, e.message);
      } on StateError catch (e) {
        // `kind` obsoleto/desconocido (p. ej. tras actualizar la app y remover
        // un handler): se aísla ESTA fila y se sigue con el resto. Antes el
        // StateError no se atrapaba y rompía todo el drenado en silencio.
        await _db.markFailed(action.id, e.message);
      }
    }
  }

  Future<void> retryFailed(String id) async {
    await (_db.update(_db.outboxActions)..where((t) => t.id.equals(id))).write(
      const OutboxActionsCompanion(status: Value('pending')),
    );
    await drain();
  }

  Stream<List<OutboxAction>> watchQueue() => _db.watchQueue();
}

final offlineQueueProvider = Provider<OfflineQueue>(
  (ref) => OfflineQueue(ref, ref.watch(appDatabaseProvider)),
);
