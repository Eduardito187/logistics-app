import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ulid/ulid.dart';

import '../api/export.dart';
import '../background/sync_scheduler.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'app_database.dart';
import 'failure_reporter.dart';
import 'sync_retry_policy.dart';

/// Directorio persistente donde se copian las fotos pendientes
/// (`<documentos>/pending_photos`). Overridable en tests.
final pendingPhotosDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => () async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'pending_photos'));
  },
);

/// Cola offline-first de FOTOS de evidencia (POD / daños).
///
/// La subida multipart (`uploadDeliveryPhoto`) no puede esperar a la red: la
/// foto se copia a un directorio persistente de la app y se encola con un `id`
/// idempotente (ULID). `drain()` reintenta las pendientes; al subir bien borra
/// la fila y el archivo local. Se dispara al recuperar conexión desde
/// `ConnectivityNotifier`, al arrancar y desde la tarea de fondo.
///
/// Misma política que las acciones ([SyncRetryPolicy]): sin red/401 corta y
/// reintenta luego, 429/5xx suman intentos hasta el tope, el resto de 4xx pasa
/// a `failed` y se reporta. El archivo de una foto `failed` se conserva hasta
/// la purga (7 días o cierre de sesión), que lo borra junto con la fila.
class PhotoUploadQueue {
  PhotoUploadQueue(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

  /// Evita drenados concurrentes solapados.
  bool _draining = false;

  /// Encola una foto para subirla idempotentemente aunque no haya red.
  ///
  /// [filePath] es la ruta devuelta por el picker (caché efímera); se copia a un
  /// directorio persistente antes de encolar. [kind] es `pod` | `damage` |
  /// `signature` | `id_document`. [clientSnapshot] (anti-fraude) liga la
  /// evidencia al cliente; se persiste junto a la foto (sidecar JSON) para
  /// sobrevivir offline y se manda al subir.
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
    Map<String, Object?>? clientSnapshot,
  }) async {
    final id = Ulid().toString();
    final persistentPath = await _persistPhoto(id, filePath);
    if (clientSnapshot != null) {
      await _writeSnapshot(persistentPath, id, clientSnapshot);
    }
    await _db.enqueuePhoto(
      PendingPhotosCompanion.insert(
        id: id,
        shipmentId: shipmentId,
        filePath: persistentPath,
        kind: Value(kind),
      ),
    );
    // Intento inmediato en segundo plano; si queda pendiente se programa la
    // tarea de fondo para subirla aunque se cierre la app.
    unawaited(_drainThenSchedule());
  }

  Future<void> _drainThenSchedule() async {
    try {
      await drain();
      if (await _db.countPendingPhotos() > 0) {
        await _ref.read(syncSchedulerProvider).scheduleOneOff();
      }
    } on Object {
      // Best-effort: la reconexión o el periódico vuelven a intentar.
    }
  }

  /// Reintenta todas las fotos pendientes. Se llama al recuperar señal.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      // Solo se leen metadatos y rutas: la foto se sube en streaming desde
      // disco (multipart), nunca se carga entera en memoria. Por lotes de
      // [_drainBatchSize]: cada fila del lote se borra, pasa a `failed` o corta
      // el drenado, así que el siguiente lote siempre avanza.
      while (true) {
        final batch = await _db.pendingPhotoRows(limit: _drainBatchSize);
        if (!await _drainBatch(batch)) return;
        if (batch.length < _drainBatchSize) return;
      }
    } finally {
      _draining = false;
    }
  }

  /// Fotos leídas por lote al drenar.
  static const int _drainBatchSize = 25;

  /// Sube un lote. Devuelve `false` si hay que cortar el drenado (sin red,
  /// 401 o 429/5xx).
  Future<bool> _drainBatch(List<PendingPhoto> batch) async {
    for (final photo in batch) {
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
        await _safeDelete(_snapshotFileFor(photo.filePath, photo.id));
      } on ApiException catch (e) {
        final attempts = photo.attempts + 1;
        if (SyncRetryPolicy.isTransient(e)) {
          if (!SyncRetryPolicy.countsAsAttempt(e)) {
            // Sin red o 401: se corta el drenado, se reintenta luego.
            return false;
          }
          if (attempts < SyncRetryPolicy.maxServerAttempts) {
            // 429/5xx: suma el intento y corta (el servidor está mal).
            await _db.markPhotoTransientFailure(photo.id, e.message, attempts);
            return false;
          }
          await _fail(photo, e, attempts, OutboxFailureReason.retriesExhausted);
          continue;
        }
        // Error de datos (4xx): no sirve reintentar, se marca fallida.
        await _fail(photo, e, attempts, OutboxFailureReason.rejected);
      }
    }
    return true;
  }

  Future<void> _fail(
    PendingPhoto photo,
    ApiException e,
    int attempts,
    OutboxFailureReason reason,
  ) async {
    await _db.markPhotoFailed(photo.id, e.message, attempts);
    await reportSafely(
      _ref.read(failureReporterProvider),
      OutboxFailure(
        id: photo.id,
        queue: OutboxQueueType.photo,
        kind: photo.kind,
        reason: reason,
        status: e.status == 0 ? null : e.status,
        problemCode: e.code?.json,
        attempts: attempts,
        occurredAt: photo.createdAt,
      ),
    );
  }

  /// Observa la cola de fotos para la UI de sincronización.
  Stream<List<PendingPhoto>> watch() => _db.watchPhotos();

  /// Borra las fotos `failed` (fila + archivo). Con [before], solo las
  /// encoladas antes de ese instante. Nunca toca las pendientes.
  Future<int> purgeFailed({DateTime? before}) async {
    final rows = await _db.failedPhotoRows(before: before);
    for (final photo in rows) {
      await _db.deletePhoto(photo.id);
      await _safeDelete(File(photo.filePath));
      await _safeDelete(_snapshotFileFor(photo.filePath, photo.id));
    }
    return rows.length;
  }

  /// Borra los archivos del directorio de fotos que ninguna fila referencia
  /// (p. ej. la app murió entre copiar y encolar, o falló un borrado).
  Future<int> sweepOrphanFiles() async {
    final Directory dir;
    try {
      dir = await _ref.read(pendingPhotosDirectoryProvider)();
    } on Object {
      return 0;
    }
    if (!dir.existsSync()) return 0;
    final referenced = await _db.photoFilePaths();
    final normalized = {for (final path in referenced) p.normalize(path)};
    // Ids de las fotos vigentes (el archivo es `<id><ext>`), para conservar su
    // snapshot `<id>.snapshot.json` mientras la foto siga encolada.
    final referencedIds = {
      for (final path in referenced) p.basenameWithoutExtension(path),
    };
    var removed = 0;
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.endsWith('.snapshot.json')) {
        final id = name.substring(0, name.length - '.snapshot.json'.length);
        if (referencedIds.contains(id)) continue;
      } else if (normalized.contains(p.normalize(entity.path))) {
        continue;
      }
      await _safeDelete(entity);
      removed++;
    }
    return removed;
  }

  Future<void> _upload(PendingPhoto photo, File file) async {
    // Firma y documento del cliente: endpoint de EVIDENCIA anti-fraude, que
    // liga la captura al cliente (snapshot) y la valida en el backend.
    if (photo.kind == 'signature' || photo.kind == 'id_document') {
      await _uploadEvidence(photo, file);
      return;
    }
    // POD / daños: endpoint estable de siempre.
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

  /// Sube la evidencia (firma / documento) al endpoint anti-fraude
  /// `POST /app/deliveries/evidence` (multipart), ligada al cliente con el
  /// snapshot persistido y con `Idempotency-Key` = id de la foto. Se usa Dio
  /// crudo (el cliente generado aún no tiene este endpoint).
  Future<void> _uploadEvidence(PendingPhoto photo, File file) async {
    final dio = _ref.read(dioProvider);
    final snapshot = await _readSnapshot(photo.filePath, photo.id);
    final form = FormData.fromMap({
      'shipment_id': photo.shipmentId,
      'kind': photo.kind,
      'photo': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
      ),
      if (snapshot != null)
        for (final e in snapshot.entries)
          if (e.value != null) e.key: '${e.value}',
    });
    try {
      await dio.post<dynamic>(
        '/app/deliveries/evidence',
        data: form,
        options: Options(headers: {'Idempotency-Key': photo.id}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Snapshot del cliente (sidecar JSON junto a la foto) -------------------

  /// Archivo del snapshot para una foto: `<dir>/<id>.snapshot.json`.
  File _snapshotFileFor(String photoPath, String id) =>
      File(p.join(p.dirname(photoPath), '$id.snapshot.json'));

  Future<void> _writeSnapshot(
    String photoPath,
    String id,
    Map<String, Object?> snapshot,
  ) async {
    try {
      await _snapshotFileFor(photoPath, id).writeAsString(jsonEncode(snapshot));
    } on Object {
      // Sin snapshot la evidencia igual se sube (menos ligada); no bloquea.
    }
  }

  Future<Map<String, Object?>?> _readSnapshot(
    String photoPath,
    String id,
  ) async {
    try {
      final f = _snapshotFileFor(photoPath, id);
      if (!f.existsSync()) return null;
      final decoded = jsonDecode(await f.readAsString());
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on Object {
      return null;
    }
  }

  /// Copia la foto a `<documentos>/pending_photos/<id><ext>` para que sobreviva
  /// a que el picker borre el archivo de caché.
  Future<String> _persistPhoto(String id, String sourcePath) async {
    final photosDir = await _ref.read(pendingPhotosDirectoryProvider)();
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
