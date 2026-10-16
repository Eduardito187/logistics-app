import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'offline_queue.dart';
import 'photo_upload_queue.dart';
import 'sync_retry_policy.dart';

/// Operaciones de mantenimiento sobre AMBAS colas offline (acciones + fotos):
/// drenado conjunto, purga de `failed` viejos y limpieza al cerrar sesión.
///
/// La usan el arranque (`drainOnStartup`), la tarea de fondo y `signOut`.
/// Ningún método lanza: todo es best-effort (la cola nunca debe trabar ni el
/// arranque ni el cierre de sesión).
class SyncMaintenance {
  SyncMaintenance(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

  /// `true` si queda algo pendiente de subir en cualquiera de las colas.
  Future<bool> hasPending() async {
    try {
      return await _db.countPendingActions() > 0 ||
          await _db.countPendingPhotos() > 0;
    } on Object {
      return false;
    }
  }

  /// Drena acciones y luego fotos, en serie (liviano para 1 GB de RAM: nunca
  /// dos subidas a la vez desde acá).
  Future<void> drainAll() async {
    try {
      await _ref.read(offlineQueueProvider).drain();
    } on Object {
      // Una cola rota no impide intentar la otra.
    }
    try {
      await _ref.read(photoUploadQueueProvider).drain();
    } on Object {
      // Best-effort.
    }
  }

  /// Purga las filas `failed` (ya reportadas) con más de
  /// [SyncRetryPolicy.failedRetention], sus archivos de foto y los archivos
  /// huérfanos. Nunca toca las pendientes. Devuelve filas/archivos borrados.
  Future<int> purgeStale({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(
      SyncRetryPolicy.failedRetention,
    );
    return _purge(before: cutoff);
  }

  /// Limpieza al cerrar sesión: borra TODAS las filas `failed` (acciones y
  /// fotos con su archivo) y los archivos huérfanos. Las pendientes se
  /// conservan para subirlas con la próxima sesión del dispositivo.
  Future<int> clearAfterSignOut() => _purge();

  Future<int> _purge({DateTime? before}) async {
    var removed = 0;
    try {
      removed += await _db.purgeFailedActions(before: before);
    } on Object {
      // Best-effort.
    }
    try {
      final photos = _ref.read(photoUploadQueueProvider);
      removed += await photos.purgeFailed(before: before);
      removed += await photos.sweepOrphanFiles();
    } on Object {
      // Best-effort.
    }
    return removed;
  }

  /// Antes de cerrar sesión: intenta subir lo pendiente con el token que aún
  /// está vigente, con un tope corto para no trabar el cierre. Lo que no suba
  /// queda pendiente (no se pierde).
  Future<void> drainBeforeSignOut({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      if (!await hasPending()) return;
      await drainAll().timeout(timeout);
    } on Object {
      // Timeout o error: lo pendiente queda para el próximo login.
    }
  }
}

final syncMaintenanceProvider = Provider<SyncMaintenance>(
  (ref) => SyncMaintenance(ref, ref.watch(appDatabaseProvider)),
);

/// [SyncMaintenance] solo si la base local ya está abierta en este contenedor
/// (si no, `null`). Lo usa `signOut` para no abrir la base solo para cerrar
/// sesión: en la app la abre `drainOnStartup` al arrancar, así que en la
/// práctica siempre está; en tests sin base evita tocar el disco.
SyncMaintenance? syncMaintenanceIfOpen(Ref ref) =>
    ref.exists(appDatabaseProvider) ? ref.read(syncMaintenanceProvider) : null;
