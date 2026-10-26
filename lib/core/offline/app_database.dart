import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `sqlite3` entra de forma transitiva por Drift; solo se usa el tipo de la
// conexión para configurar `busy_timeout`.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/common.dart' show CommonDatabase;

import 'outbox_actions_table.dart';
import 'pending_photos_table.dart';

// Las tablas Drift viven en su propio archivo (una clase por archivo). Se
// reexportan para que el patrón actual de importar solo `offline/app_database.dart`
// siga dando acceso a [OutboxActions] y [PendingPhotos] y a sus data classes
// generadas (OutboxAction, PendingPhoto, *Companion), que viven en el .g.dart.
export 'outbox_actions_table.dart';
export 'pending_photos_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [OutboxActions, PendingPhotos])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'logistics_app',
              native: const DriftNativeOptions(setup: _configureConnection),
            ),
      );

  /// PRAGMAs de cada conexión, pensados para gama baja (1 GB de RAM):
  ///
  /// - `busy_timeout`: la tarea de fondo (WorkManager) abre su propia conexión
  ///   al mismo archivo mientras la app puede estar abierta; SQLite espera el
  ///   lock unos segundos en vez de fallar con "database is locked".
  /// - `journal_mode = WAL`: el que escribe (escaneo, GPS) no bloquea al que
  ///   lee (pantalla de sync, drenado), y cada commit escribe menos en disco.
  ///   `synchronous` queda en el default (FULL): un escaneo confirmado no se
  ///   pierde ni con un corte de batería.
  /// - `journal_size_limit` 1 MB: el archivo `-wal` se recorta tras cada
  ///   checkpoint en vez de quedar del tamaño del pico (días sin señal).
  /// - `cache_size` -1024 = 1 MB de páginas por conexión (default 2 MB): la
  ///   base es chica y las consultas calientes van por índice.
  /// - `temp_store = FILE`: ordenamientos temporales a disco, no a RAM.
  static const List<String> connectionPragmas = [
    'PRAGMA busy_timeout = 5000;',
    'PRAGMA journal_mode = WAL;',
    'PRAGMA journal_size_limit = 1048576;',
    'PRAGMA cache_size = -1024;',
    'PRAGMA temp_store = FILE;',
  ];

  /// Aplica [connectionPragmas] a una conexión recién abierta.
  /// Estática: se envía al isolate donde se abre la conexión.
  static void configureConnection(CommonDatabase db) {
    for (final pragma in connectionPragmas) {
      db.execute(pragma);
    }
  }

  static void _configureConnection(CommonDatabase db) =>
      configureConnection(db);

  @override
  int get schemaVersion => 3;

  /// Tope de filas que emite [watchQueue]: la pantalla de sincronización no
  /// necesita miles de filas en memoria (en un teléfono de 1 GB, una cola
  /// acumulada de días sin señal podría pesar varios MB).
  static const int queueWatchLimit = 200;

  /// Índices de las consultas calientes (drenado y pantalla de sync). Se crean
  /// con SQL directo (`IF NOT EXISTS`) para no depender de regenerar el código
  /// de Drift; son idempotentes al crear y al migrar.
  static const List<String> indexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_outbox_status_id '
        'ON outbox_actions (status, id)',
    'CREATE INDEX IF NOT EXISTS idx_outbox_created_at '
        'ON outbox_actions (created_at)',
    'CREATE INDEX IF NOT EXISTS idx_photos_status_id '
        'ON pending_photos (status, id)',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // v2: cola de fotos de evidencia (POD / daños).
      if (from < 2) {
        await m.createTable(pendingPhotos);
      }
      // v3: índices para el drenado por lotes y el stream de la cola.
      if (from < 3) {
        await _createIndexes();
      }
    },
  );

  Future<void> _createIndexes() async {
    for (final sql in indexStatements) {
      await customStatement(sql);
    }
  }

  /// Acciones pendientes en orden de creación (ULID). [limit] permite drenar
  /// por lotes sin cargar toda la cola (con sus payloads) en memoria.
  Future<List<OutboxAction>> pendingActions({
    int? limit,
    Set<String> excludeIds = const {},
  }) {
    final query = select(outboxActions)
      ..where((t) => t.status.equals('pending'));
    // Filas con un envío en curso (OfflineQueue): no se reenvían en paralelo.
    if (excludeIds.isNotEmpty) {
      query.where((t) => t.id.isNotIn(excludeIds));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// Cantidad de acciones pendientes con `COUNT(*)` (no trae las filas).
  Future<int> countPendingActions() async {
    final count = outboxActions.id.count();
    final row =
        await (selectOnly(outboxActions)
              ..addColumns([count])
              ..where(outboxActions.status.equals('pending')))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Cola para la UI de sincronización, más reciente primero.
  ///
  /// Liviana a propósito: NO lee la columna `payload` (el JSON de la request,
  /// lo más pesado de cada fila), así que las filas emitidas traen
  /// `payload == ''`. Para reenviar se usa [pendingActions], que sí lo lee.
  /// Emite como mucho [limit] filas (por defecto [queueWatchLimit]).
  Stream<List<OutboxAction>> watchQueue({int limit = queueWatchLimit}) {
    final t = outboxActions;
    final columns = <Expression<Object>>[
      t.id,
      t.kind,
      t.occurredAt,
      t.status,
      t.attempts,
      t.lastError,
      t.createdAt,
      t.label,
    ];
    final query = selectOnly(t)
      ..addColumns(columns)
      ..where(t.status.isNotValue('done'))
      ..orderBy([OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          OutboxAction(
            id: row.read(t.id)!,
            kind: row.read(t.kind)!,
            payload: '',
            occurredAt: row.read(t.occurredAt)!,
            status: row.read(t.status)!,
            attempts: row.read(t.attempts)!,
            lastError: row.read(t.lastError),
            createdAt: row.read(t.createdAt)!,
            label: row.read(t.label),
          ),
      ],
    );
  }

  Future<void> enqueue(OutboxActionsCompanion action) =>
      into(outboxActions).insert(action, mode: InsertMode.insertOrIgnore);

  Future<void> markSynced(String id) =>
      (delete(outboxActions)..where((t) => t.id.equals(id))).go();

  Future<void> markFailed(String id, String error) async {
    // Se incrementa `attempts` en cada fallo: así hay base para backoff y un
    // tope de reintentos. Se usa SQL directo porque el Companion solo admite
    // valores constantes, no `attempts = attempts + 1` sobre la fila actual.
    await customUpdate(
      'UPDATE outbox_actions '
      'SET status = ?, last_error = ?, attempts = attempts + 1 '
      'WHERE id = ?',
      variables: [
        Variable<String>('failed'),
        Variable<String>(error),
        Variable<String>(id),
      ],
      updates: {outboxActions},
    );
  }

  /// Fallo transitorio con respuesta del servidor (429/5xx): suma un intento y
  /// guarda el error, pero la fila SIGUE `pending` (se reintenta con backoff).
  Future<void> markTransientFailure(String id, String error) async {
    await customUpdate(
      'UPDATE outbox_actions '
      'SET last_error = ?, attempts = attempts + 1 '
      'WHERE id = ?',
      variables: [Variable<String>(error), Variable<String>(id)],
      updates: {outboxActions},
    );
  }

  /// Intentos acumulados de una acción (0 si no existe).
  Future<int> actionAttempts(String id) async {
    final row =
        await (selectOnly(outboxActions)
              ..addColumns([outboxActions.attempts])
              ..where(outboxActions.id.equals(id)))
            .getSingleOrNull();
    return row?.read(outboxActions.attempts) ?? 0;
  }

  /// Borra las acciones `failed` (ya reportadas). Con [before] solo las
  /// encoladas antes de ese instante (purga por antigüedad). Nunca toca las
  /// `pending`. Devuelve cuántas borró.
  Future<int> purgeFailedActions({DateTime? before}) {
    final query = delete(outboxActions)
      ..where((t) {
        final failed = t.status.equals('failed');
        return before == null
            ? failed
            : failed & t.createdAt.isSmallerThanValue(before);
      });
    return query.go();
  }

  /// Descarta las posiciones GPS del camión (`ingestTruckPosition`) que siguen
  /// pendientes desde antes de [before]. Son las únicas acciones descartables:
  /// con días sin señal se acumulan ~360 por hora y una posición vieja ya no
  /// sirve para seguir el camión. Escaneos, entregas y fotos NUNCA se tocan.
  Future<int> purgeStaleTruckPositions({required DateTime before}) {
    final query = delete(outboxActions)
      ..where(
        (t) =>
            t.kind.equals('ingestTruckPosition') &
            t.status.equals('pending') &
            t.createdAt.isSmallerThanValue(before),
      );
    return query.go();
  }

  // --- Cola de fotos de evidencia (POD / daños) ---

  /// Cantidad de fotos pendientes con `COUNT(*)`.
  Future<int> countPendingPhotos() async {
    final count = pendingPhotos.id.count();
    final row =
        await (selectOnly(pendingPhotos)
              ..addColumns([count])
              ..where(pendingPhotos.status.equals('pending')))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Fotos `failed` (con [before], solo las encoladas antes de ese instante).
  /// Se devuelven las filas para poder borrar también el archivo en disco.
  Future<List<PendingPhoto>> failedPhotoRows({DateTime? before}) {
    final query = select(pendingPhotos)
      ..where((t) {
        final failed = t.status.equals('failed');
        return before == null
            ? failed
            : failed & t.createdAt.isSmallerThanValue(before);
      });
    return query.get();
  }

  /// Rutas de todas las fotos que siguen en la cola (pendientes o fallidas):
  /// cualquier otro archivo del directorio de fotos es huérfano.
  Future<Set<String>> photoFilePaths() async {
    final rows = await (selectOnly(
      pendingPhotos,
    )..addColumns([pendingPhotos.filePath])).get();
    return {for (final r in rows) r.read(pendingPhotos.filePath)!};
  }

  /// Fallo transitorio de una foto (429/5xx): suma el intento y deja la fila
  /// `pending`.
  Future<void> markPhotoTransientFailure(
    String id,
    String error,
    int attempts,
  ) {
    return (update(pendingPhotos)..where((t) => t.id.equals(id))).write(
      PendingPhotosCompanion(
        lastError: Value(error),
        attempts: Value(attempts),
      ),
    );
  }

  Future<void> enqueuePhoto(PendingPhotosCompanion photo) =>
      into(pendingPhotos).insert(photo, mode: InsertMode.insertOrIgnore);

  /// Fotos pendientes (solo metadatos y ruta: la imagen queda en disco).
  Future<List<PendingPhoto>> pendingPhotoRows({int? limit}) {
    final query = select(pendingPhotos)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// Fotos de la cola para la UI de sincronización, más reciente primero.
  /// Solo metadatos (la imagen queda en disco) y como mucho [limit] filas.
  Stream<List<PendingPhoto>> watchPhotos({int limit = queueWatchLimit}) {
    return (select(pendingPhotos)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> deletePhoto(String id) =>
      (delete(pendingPhotos)..where((t) => t.id.equals(id))).go();

  Future<void> markPhotoFailed(String id, String error, int attempts) {
    return (update(pendingPhotos)..where((t) => t.id.equals(id))).write(
      PendingPhotosCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        attempts: Value(attempts),
      ),
    );
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
