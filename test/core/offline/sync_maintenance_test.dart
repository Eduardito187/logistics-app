import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/offline/sync_maintenance.dart';
import 'package:path/path.dart' as p;

import 'offline_test_fakes.dart';

// Mantenimiento conjunto de las colas: purga de failed viejos, limpieza al
// cerrar sesión (sin tocar pendientes) y drenado previo al cierre.

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ScriptedExecution exec;
  late ProviderContainer container;
  late SyncMaintenance maintenance;

  void build(List<Object?> script) {
    exec = ScriptedExecution(script.cast());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        logisticsApiProvider.overrideWithValue(FakeSyncApi(exec)),
        failureReporterProvider.overrideWithValue(RecordingReporter()),
        syncSchedulerProvider.overrideWithValue(CountingScheduler()),
        pendingPhotosDirectoryProvider.overrideWithValue(() async => tmp),
      ],
    );
    maintenance = container.read(syncMaintenanceProvider);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('maint_test_');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> action(
    String id,
    String status,
    DateTime createdAt, {
    String kind = 'recordLoadScan',
  }) => db.enqueue(
    OutboxActionsCompanion.insert(
      id: id,
      kind: kind,
      payload:
          '{"shipment_id":"s1","unit_id":"u1","lat":0,"lng":0,'
          '"occurred_at":"2026-10-15T12:00:00.000Z"}',
      occurredAt: createdAt,
      status: Value(status),
      createdAt: Value(createdAt),
    ),
  );

  Future<File> photo(String id, String status, DateTime createdAt) async {
    final file = File(p.join(tmp.path, '$id.jpg'))..writeAsBytesSync([1]);
    await db.enqueuePhoto(
      PendingPhotosCompanion.insert(
        id: id,
        shipmentId: 's1',
        filePath: file.path,
        status: Value(status),
        createdAt: Value(createdAt),
      ),
    );
    return file;
  }

  Future<List<String>> actionIds() async => [
    for (final r in await db.select(db.outboxActions).get()) r.id,
  ];
  Future<List<String>> photoIds() async => [
    for (final r in await db.select(db.pendingPhotos).get()) r.id,
  ];

  final now = DateTime(2026, 10, 16, 12);
  final old = now.subtract(const Duration(days: 8));
  final recent = now.subtract(const Duration(days: 2));

  test('purgeStale borra solo failed > 7 días (acciones y fotos + archivo) '
      'y nunca pendientes', () async {
    await action('A-old-failed', 'failed', old);
    await action('A-new-failed', 'failed', recent);
    await action('A-old-pending', 'pending', old);
    final oldPhoto = await photo('P-old-failed', 'failed', old);
    await photo('P-old-pending', 'pending', old);
    build([]);

    await maintenance.purgeStale(now: now);

    expect(
      await actionIds(),
      unorderedEquals(['A-new-failed', 'A-old-pending']),
    );
    expect(await photoIds(), ['P-old-pending']);
    expect(oldPhoto.existsSync(), isFalse);
  });

  test('purgeStale descarta posiciones GPS pendientes > 7 días; ninguna otra '
      'pendiente', () async {
    await action('G-old', 'pending', old, kind: 'ingestTruckPosition');
    await action('G-new', 'pending', recent, kind: 'ingestTruckPosition');
    await action('S-old', 'pending', old); // escaneo: nunca se descarta
    build([]);

    await maintenance.purgeStale(now: now);

    expect(await actionIds(), unorderedEquals(['G-new', 'S-old']));
  });

  test('clearAfterSignOut borra TODAS las failed y huérfanos; conserva la '
      'cola pendiente', () async {
    await action('A-failed', 'failed', recent);
    await action('A-pending', 'pending', recent);
    final failedPhoto = await photo('P-failed', 'failed', recent);
    final pendingPhoto = await photo('P-pending', 'pending', recent);
    final orphan = File(p.join(tmp.path, 'huerfana.jpg'))
      ..writeAsBytesSync([1]);
    build([]);

    await maintenance.clearAfterSignOut();

    expect(await actionIds(), ['A-pending']);
    expect(await photoIds(), ['P-pending']);
    expect(failedPhoto.existsSync(), isFalse);
    expect(orphan.existsSync(), isFalse);
    expect(pendingPhoto.existsSync(), isTrue);
  });

  test('hasPending refleja acciones o fotos pendientes', () async {
    build([]);
    expect(await maintenance.hasPending(), isFalse);
    await photo('P', 'pending', recent);
    expect(await maintenance.hasPending(), isTrue);
  });

  test('drainAll sube acciones y fotos', () async {
    await action('A', 'pending', recent);
    final file = await photo('P', 'pending', recent);
    build([]);
    await maintenance.drainAll();
    expect(await actionIds(), isEmpty);
    expect(await photoIds(), isEmpty);
    expect(file.existsSync(), isFalse);
    expect(exec.calls, 2);
  });

  test('drainBeforeSignOut sin pendientes no llama al API', () async {
    build([]);
    await maintenance.drainBeforeSignOut();
    expect(exec.calls, 0);
  });

  test('drainBeforeSignOut sin red conserva lo pendiente', () async {
    await action('A', 'pending', recent);
    build([connectionError(), connectionError()]);
    await maintenance.drainBeforeSignOut();
    expect(await actionIds(), ['A']);
  });

  test('drainBeforeSignOut respeta el timeout', () async {
    await action('A', 'pending', recent);
    build([]);
    final sw = Stopwatch()..start();
    await maintenance.drainBeforeSignOut(timeout: Duration.zero);
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    // Deja terminar el drenado que siguió en segundo plano antes del tearDown.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
}
