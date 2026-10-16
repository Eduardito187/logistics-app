import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    : super(executor ?? driftDatabase(name: 'logistics_app'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: cola de fotos de evidencia (POD / daños).
      if (from < 2) {
        await m.createTable(pendingPhotos);
      }
    },
  );

  Future<List<OutboxAction>> pendingActions() {
    return (select(outboxActions)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Stream<List<OutboxAction>> watchQueue() {
    return (select(outboxActions)
          ..where((t) => t.status.isNotValue('done'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
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

  // --- Cola de fotos de evidencia (POD / daños) ---

  Future<void> enqueuePhoto(PendingPhotosCompanion photo) =>
      into(pendingPhotos).insert(photo, mode: InsertMode.insertOrIgnore);

  Future<List<PendingPhoto>> pendingPhotoRows() {
    return (select(pendingPhotos)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Stream<List<PendingPhoto>> watchPhotos() {
    return (select(
      pendingPhotos,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
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
