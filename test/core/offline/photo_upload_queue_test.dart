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
import 'package:logistics_app/core/offline/sync_retry_policy.dart';
import 'package:path/path.dart' as p;

import 'offline_test_fakes.dart';

// Cola de fotos: borra el archivo al subir y al purgar, clasifica errores igual
// que las acciones y reporta los rechazos.

void main() {
  late AppDatabase db;
  late Directory tmp;
  late Directory photosDir;
  late ScriptedExecution exec;
  late RecordingReporter reporter;
  late CountingScheduler scheduler;
  late ProviderContainer container;
  late PhotoUploadQueue queue;

  void build(List<Object?> script) {
    exec = ScriptedExecution(script.cast());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        logisticsApiProvider.overrideWithValue(FakeSyncApi(exec)),
        failureReporterProvider.overrideWithValue(reporter),
        syncSchedulerProvider.overrideWithValue(scheduler),
        pendingPhotosDirectoryProvider.overrideWithValue(() async => photosDir),
      ],
    );
    queue = container.read(photoUploadQueueProvider);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('photos_test_');
    photosDir = Directory(p.join(tmp.path, 'pending_photos'))..createSync();
    reporter = RecordingReporter();
    scheduler = CountingScheduler();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File makeFile(String name) =>
      File(p.join(photosDir.path, name))..writeAsBytesSync([1, 2, 3]);

  Future<File> seed(
    String id, {
    String status = 'pending',
    int attempts = 0,
    DateTime? createdAt,
  }) async {
    final file = makeFile('$id.jpg');
    await db.enqueuePhoto(
      PendingPhotosCompanion.insert(
        id: id,
        shipmentId: 's1',
        filePath: file.path,
        status: Value(status),
        attempts: Value(attempts),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );
    return file;
  }

  Future<List<PendingPhoto>> rows() => db.select(db.pendingPhotos).get();

  test('subida OK borra la fila y el archivo del disco', () async {
    final file = await seed('A');
    build([]);
    await queue.drain();
    expect(await rows(), isEmpty);
    expect(file.existsSync(), isFalse);
  });

  test('sin red: corta, deja pending y conserva el archivo', () async {
    final file = await seed('A');
    await seed('B');
    build([connectionError()]);
    await queue.drain();
    expect((await rows()).every((r) => r.status == 'pending'), isTrue);
    expect(exec.photoCalls, 1);
    expect(file.existsSync(), isTrue);
  });

  test('401 no la marca fallida', () async {
    await seed('A');
    build([httpError(401)]);
    await queue.drain();
    expect((await rows()).single.status, 'pending');
    expect(reporter.events, isEmpty);
  });

  test('5xx suma intento y deja pending (antes la marcaba failed)', () async {
    await seed('A', attempts: 1);
    build([httpError(502)]);
    await queue.drain();
    final r = (await rows()).single;
    expect(r.status, 'pending');
    expect(r.attempts, 2);
  });

  test('tope de 5xx → failed + retries_exhausted', () async {
    await seed('A', attempts: SyncRetryPolicy.maxServerAttempts - 1);
    build([httpError(500)]);
    await queue.drain();
    expect((await rows()).single.status, 'failed');
    expect(reporter.events.single.reason, OutboxFailureReason.retriesExhausted);
  });

  test('4xx → failed, se reporta (queue photo) y el archivo se conserva '
      'hasta la purga', () async {
    final file = await seed('A');
    build([httpError(422, problemCode: 'bad_request')]);
    await queue.drain();
    expect((await rows()).single.status, 'failed');
    final e = reporter.events.single;
    expect(e.queue, OutboxQueueType.photo);
    expect(e.kind, 'pod');
    expect(e.status, 422);
    expect(e.problemCode, 'bad_request');
    expect(e.attempts, 1);
    expect(file.existsSync(), isTrue);
  });

  test('archivo inexistente: descarta la fila sin llamar al API', () async {
    final file = await seed('A');
    file.deleteSync();
    build([]);
    await queue.drain();
    expect(await rows(), isEmpty);
    expect(exec.photoCalls, 0);
  });

  group('purgeFailed', () {
    test('con before: borra solo las failed viejas, con su archivo', () async {
      final now = DateTime.now();
      final old = await seed(
        'OLD',
        status: 'failed',
        createdAt: now.subtract(const Duration(days: 8)),
      );
      final recent = await seed(
        'NEW',
        status: 'failed',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final pending = await seed(
        'PEN',
        createdAt: now.subtract(const Duration(days: 30)),
      );
      build([]);
      final removed = await queue.purgeFailed(
        before: now.subtract(const Duration(days: 7)),
      );
      expect(removed, 1);
      expect((await rows()).map((r) => r.id), unorderedEquals(['NEW', 'PEN']));
      expect(old.existsSync(), isFalse);
      expect(recent.existsSync(), isTrue);
      expect(pending.existsSync(), isTrue);
    });

    test('sin before: borra todas las failed y nunca las pending', () async {
      await seed('F1', status: 'failed');
      await seed('F2', status: 'failed');
      final pending = await seed('P');
      build([]);
      expect(await queue.purgeFailed(), 2);
      expect((await rows()).single.id, 'P');
      expect(pending.existsSync(), isTrue);
    });
  });

  test(
    'sweepOrphanFiles borra archivos sin fila y conserva los encolados',
    () async {
      final kept = await seed('A');
      final orphan = makeFile('huerfana.jpg');
      build([]);
      expect(await queue.sweepOrphanFiles(), 1);
      expect(orphan.existsSync(), isFalse);
      expect(kept.existsSync(), isTrue);
    },
  );

  test('sweepOrphanFiles sin directorio devuelve 0', () async {
    photosDir.deleteSync(recursive: true);
    build([]);
    expect(await queue.sweepOrphanFiles(), 0);
  });

  test('enqueue copia al directorio persistente y, si no sube, programa la '
      'tarea de fondo', () async {
    final source = File(p.join(tmp.path, 'picker.jpg'))
      ..writeAsBytesSync([9, 9]);
    build([connectionError()]);
    await queue.enqueue(
      shipmentId: 's1',
      filePath: source.path,
      kind: 'damage',
    );
    // El drenado inmediato corre en segundo plano.
    for (var i = 0; i < 50 && scheduler.oneOffs == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final r = (await rows()).single;
    expect(r.kind, 'damage');
    expect(p.isWithin(photosDir.path, r.filePath), isTrue);
    expect(File(r.filePath).existsSync(), isTrue);
    expect(scheduler.oneOffs, 1);
  });
}
