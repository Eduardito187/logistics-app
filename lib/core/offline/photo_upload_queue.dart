import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ulid/ulid.dart';

import '../api/export.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'app_database.dart';

/// Cola offline-first de FOTOS de evidencia (POD / daños).
///
/// La subida multipart (`uploadDeliveryPhoto`) no puede esperar a la red: la
/// foto se copia a un directorio persistente de la app y se encola con un `id`
/// idempotente (ULID). `drain()` reintenta las pendientes; al subir bien borra
/// la fila y el archivo local. Se dispara al recuperar conexión desde
/// `ConnectivityNotifier` (offline_queue.dart), reusando esa suscripción.
class PhotoUploadQueue {
  PhotoUploadQueue(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

  /// Evita drenados concurrentes solapados.
  bool _draining = false;

  /// Encola una foto para subirla idempotentemente aunque no haya red.
  ///
  /// [filePath] es la ruta devuelta por el picker (caché efímera); se copia a un
  /// directorio persistente antes de encolar. [kind] es `pod` o `damage`.
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) async {
    final id = Ulid().toString();
    final persistentPath = await _persistPhoto(id, filePath);
    await _db.enqueuePhoto(
      PendingPhotosCompanion.insert(
        id: id,
        shipmentId: shipmentId,
        filePath: persistentPath,
        kind: Value(kind),
      ),
    );
    // Intento inmediato en segundo plano; si no hay red queda para el sync.
    unawaited(drain());
  }

  /// Reintenta todas las fotos pendientes. Se llama al recuperar señal.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final pending = await _db.pendingPhotoRows();
      for (final photo in pending) {
        final file = File(photo.filePath);
        if (!file.existsSync()) {
          // El archivo ya no está: no hay nada que subir, se descarta la fila.
          await _db.deletePhoto(photo.id);
          continue;
        }
        try {
          await _upload(photo, file);
          await _db.deletePhoto(photo.id);
          await _safeDelete(file);
        } on ApiException catch (e) {
          if (e.isConnectionError) {
            // Sigue sin red: se corta el drenado, se reintenta luego.
            break;
          }
          // Error de datos (4xx): no sirve reintentar, se marca fallida.
          await _db.markPhotoFailed(photo.id, e.message, photo.attempts + 1);
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Observa la cola de fotos para la UI de sincronización.
  Stream<List<PendingPhoto>> watch() => _db.watchPhotos();

  Future<void> _upload(PendingPhoto photo, File file) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      await api.execution.uploadDeliveryPhoto(
        shipmentId: photo.shipmentId,
        photo: file,
        kind: _kindToEnum(photo.kind),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Copia la foto a `<documentos>/pending_photos/<id><ext>` para que sobreviva
  /// a que el picker borre el archivo de caché.
  Future<String> _persistPhoto(String id, String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'pending_photos'));
    if (!photosDir.existsSync()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final dest = p.join(photosDir.path, '$id$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Borrar el archivo local es best-effort: la fila ya se eliminó.
    }
  }

  Enum0 _kindToEnum(String kind) => kind == 'damage' ? Enum0.damage : Enum0.pod;
}

final photoUploadQueueProvider = Provider<PhotoUploadQueue>(
  (ref) => PhotoUploadQueue(ref, ref.watch(appDatabaseProvider)),
);
