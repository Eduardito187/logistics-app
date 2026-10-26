// Se oculta `isNull` de drift para usar el matcher homónimo de flutter_test.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';

// Vectores de apoyo.
OutboxActionsCompanion _action(
  String id, {
  String kind = 'recordLoadScan',
  String status = 'pending',
  String payload = '{}',
  DateTime? createdAt,
  String? label,
}) {
  return OutboxActionsCompanion.insert(
    id: id,
    kind: kind,
    payload: payload,
    occurredAt: DateTime.utc(2026, 1, 1),
    status: Value(status),
    createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    label: label == null ? const Value.absent() : Value(label),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    // Base en memoria: sin archivo, aislada por test (requiere la lib nativa
    // sqlite3 en el host, estándar para los tests de Drift).
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<OutboxAction>> allRows() => db.select(db.outboxActions).get();

  group('enqueue', () {
    test('inserta una acción pendiente con sus valores por defecto', () async {
      await db.enqueue(_action('a', label: 'Carga · pedido 1'));
      final rows = await allRows();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'a');
      expect(rows.single.kind, 'recordLoadScan');
      expect(rows.single.status, 'pending');
      expect(rows.single.attempts, 0);
      expect(rows.single.lastError, isNull);
      expect(rows.single.label, 'Carga · pedido 1');
    });

    test(
      'insertOrIgnore: un segundo insert con el mismo id NO duplica',
      () async {
        await db.enqueue(_action('dup', payload: '{"v":1}'));
        // Segundo intento con mismo id y payload distinto: debe ignorarse,
        // preservando la fila original (idempotencia del outbox).
        await db.enqueue(_action('dup', payload: '{"v":2}', status: 'failed'));
        final rows = await allRows();
        expect(rows, hasLength(1));
        expect(rows.single.payload, '{"v":1}');
        expect(rows.single.status, 'pending');
      },
    );
  });

  group('pendingActions', () {
    test('solo devuelve las pending y ordenadas por id ascendente', () async {
      await db.enqueue(_action('c'));
      await db.enqueue(_action('a'));
      await db.enqueue(_action('b', status: 'failed'));
      await db.enqueue(_action('d'));

      final pending = await db.pendingActions();
      expect(pending.map((r) => r.id).toList(), <String>['a', 'c', 'd']);
    });

    test('lista vacía cuando no hay pendientes', () async {
      await db.enqueue(_action('x', status: 'failed'));
      expect(await db.pendingActions(), isEmpty);
    });
  });

  group('markSynced', () {
    test('borra la fila (las sincronizadas no se conservan)', () async {
      await db.enqueue(_action('a'));
      await db.markSynced('a');
      expect(await allRows(), isEmpty);
    });

    test('no afecta a otras filas', () async {
      await db.enqueue(_action('a'));
      await db.enqueue(_action('b'));
      await db.markSynced('a');
      final rows = await allRows();
      expect(rows.map((r) => r.id), <String>['b']);
    });
  });

  group('markFailed', () {
    test('cambia status a failed y guarda el último error', () async {
      await db.enqueue(_action('a'));
      await db.markFailed('a', 'Datos inválidos');
      final row = (await allRows()).single;
      expect(row.status, 'failed');
      expect(row.lastError, 'Datos inválidos');
    });

    // markFailed incrementa `attempts` en cada fallo: base para backoff y un
    // tope de reintentos.
    test('attempts se incrementa en cada fallo', () async {
      await db.enqueue(_action('a'));
      await db.markFailed('a', 'e1');
      await db.markFailed('a', 'e2');
      expect((await allRows()).single.attempts, 2);
    });
  });

  group('watchQueue', () {
    test(
      'emite las filas no-"done" ordenadas por createdAt descendente',
      () async {
        await db.enqueue(_action('old', createdAt: DateTime.utc(2026, 1, 1)));
        await db.enqueue(
          _action('new', status: 'failed', createdAt: DateTime.utc(2026, 1, 3)),
        );
        await db.enqueue(_action('mid', createdAt: DateTime.utc(2026, 1, 2)));

        final rows = await db.watchQueue().first;
        // Más reciente primero: new (03), mid (02), old (01). Incluye pending y
        // failed porque el filtro solo excluye 'done'.
        expect(rows.map((r) => r.id).toList(), <String>['new', 'mid', 'old']);
      },
    );

    test('una fila sincronizada (borrada) desaparece del stream', () async {
      await db.enqueue(_action('a'));
      expect(await db.watchQueue().first, hasLength(1));
      await db.markSynced('a');
      expect(await db.watchQueue().first, isEmpty);
    });
  });

  group('cola de fotos de evidencia', () {
    PendingPhotosCompanion photo(String id, {String kind = 'pod'}) {
      return PendingPhotosCompanion.insert(
        id: id,
        shipmentId: 's1',
        filePath: '/tmp/$id.jpg',
        kind: Value(kind),
      );
    }

    test(
      'enqueuePhoto + pendingPhotoRows filtra pending y ordena por id',
      () async {
        await db.enqueuePhoto(photo('b'));
        await db.enqueuePhoto(photo('a'));
        final pending = await db.pendingPhotoRows();
        expect(pending.map((r) => r.id).toList(), <String>['a', 'b']);
      },
    );

    test('enqueuePhoto es insertOrIgnore (no duplica por id)', () async {
      await db.enqueuePhoto(photo('a'));
      await db.enqueuePhoto(photo('a'));
      final all = await db.select(db.pendingPhotos).get();
      expect(all, hasLength(1));
    });

    test('markPhotoFailed guarda error, status y attempts', () async {
      await db.enqueuePhoto(photo('a'));
      await db.markPhotoFailed('a', 'sin red', 3);
      final row = (await db.select(db.pendingPhotos).get()).single;
      expect(row.status, 'failed');
      expect(row.lastError, 'sin red');
      expect(row.attempts, 3);
    });

    test('deletePhoto borra la fila', () async {
      await db.enqueuePhoto(photo('a'));
      await db.deletePhoto('a');
      expect(await db.select(db.pendingPhotos).get(), isEmpty);
    });

    test('watchPhotos emite todas las fotos (sin filtrar status)', () async {
      await db.enqueuePhoto(photo('a'));
      await db.markPhotoFailed('a', 'e', 1);
      await db.enqueuePhoto(photo('b'));
      final rows = await db.watchPhotos().first;
      expect(rows, hasLength(2));
    });
  });

  group('gama baja (PRAGMAs y topes)', () {
    test('las PRAGMAs de conexión se aplican sin error', () async {
      final configured = AppDatabase(
        NativeDatabase.memory(setup: AppDatabase.configureConnection),
      );
      addTearDown(configured.close);
      final row = await configured
          .customSelect('PRAGMA busy_timeout')
          .getSingle();
      expect(row.data.values.single, 5000);
      final cache = await configured
          .customSelect('PRAGMA cache_size')
          .getSingle();
      expect(cache.data.values.single, -1024);
      final limit = await configured
          .customSelect('PRAGMA journal_size_limit')
          .getSingle();
      expect(limit.data.values.single, 1048576);
    });

    test('pide WAL, journal acotado y caché de 1 MB', () {
      expect(
        AppDatabase.connectionPragmas,
        contains('PRAGMA journal_mode = WAL;'),
      );
      expect(
        AppDatabase.connectionPragmas.any((p) => p.contains('synchronous')),
        isFalse,
        reason: 'synchronous queda en FULL: un escaneo no se pierde',
      );
    });

    test('watchPhotos respeta el tope de filas', () async {
      for (var i = 0; i < 5; i++) {
        await db.enqueuePhoto(
          PendingPhotosCompanion.insert(
            id: 'p$i',
            shipmentId: 's',
            filePath: '/tmp/p$i.jpg',
          ),
        );
      }
      expect(await db.watchPhotos(limit: 3).first, hasLength(3));
      expect(await db.watchPhotos().first, hasLength(5));
    });
  });
}
