import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/execution_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/delivery_status.dart';
import 'package:logistics_app/core/api/models/post_app_deliveries_scans_load_response.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';

// Optimizaciones de memoria de la cola offline (teléfonos de 1 GB): índices,
// stream liviano sin payload, COUNT(*) y drenado por lotes sin solaparse.

const _loadOk = PostAppDeliveriesScansLoadResponse(
  data: Delivery(
    id: 'd1',
    shipmentId: 's1',
    vehicleId: 'v1',
    status: DeliveryStatus.loaded,
    scans: [],
  ),
);

/// Cliente falso: cuenta llamadas y responde éxito; [gate] permite frenar la
/// primera llamada para simular un drenado en curso.
class _FakeExecution implements ExecutionClient {
  _FakeExecution({this.gate});

  final Completer<void>? gate;
  final List<String?> keys = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    keys.add(invocation.namedArguments[#idempotencyKey] as String?);
    return Future<PostAppDeliveriesScansLoadResponse>(() async {
      if (gate != null && !gate!.isCompleted) await gate!.future;
      return _loadOk;
    });
  }
}

class _FakeApi extends LogisticsApi {
  _FakeApi(this._execution) : super(Dio());
  final ExecutionClient _execution;
  @override
  ExecutionClient get execution => _execution;
}

Map<String, Object?> _scanPayload() => {
  'shipment_id': 's1',
  'unit_id': 'u1',
  'lat': -16.5,
  'lng': -68.1,
  'occurred_at': '2026-10-15T12:00:00.000Z',
};

OutboxActionsCompanion _action(
  String id, {
  String status = 'pending',
  String? payload,
  DateTime? createdAt,
}) {
  return OutboxActionsCompanion.insert(
    id: id,
    kind: 'recordLoadScan',
    payload: payload ?? jsonEncode(_scanPayload()),
    occurredAt: DateTime.utc(2026, 1, 1),
    status: Value(status),
    createdAt: Value(createdAt ?? DateTime.utc(2026, 1, 1)),
    label: const Value('Carga'),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('AppDatabase', () {
    test('crea los índices de las consultas calientes', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_%'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names, {
        'idx_outbox_status_id',
        'idx_outbox_created_at',
        'idx_photos_status_id',
      });
    });

    test('schemaVersion 3 (v3 agrega los índices)', () {
      expect(db.schemaVersion, 3);
    });

    test('countPendingActions cuenta solo las pending con COUNT(*)', () async {
      expect(await db.countPendingActions(), 0);
      await db.enqueue(_action('a'));
      await db.enqueue(_action('b'));
      await db.enqueue(_action('c', status: 'failed'));
      expect(await db.countPendingActions(), 2);
    });

    test('pendingActions(limit) devuelve un lote en orden de id', () async {
      for (final id in ['c', 'a', 'b']) {
        await db.enqueue(_action(id));
      }
      final batch = await db.pendingActions(limit: 2);
      expect(batch.map((a) => a.id), ['a', 'b']);
      // El lote sí trae el payload: es lo que se reenvía.
      expect(batch.first.payload, contains('shipment_id'));
    });

    test('watchQueue no carga el payload (filas livianas)', () async {
      await db.enqueue(_action('a', payload: '{"big":"${'x' * 5000}"}'));
      final rows = await db.watchQueue().first;
      expect(rows.single.id, 'a');
      expect(rows.single.payload, isEmpty);
      // El resto de los campos que usa la UI sí viene.
      expect(rows.single.label, 'Carga');
      expect(rows.single.kind, 'recordLoadScan');
      expect(rows.single.status, 'pending');
    });

    test('watchQueue respeta el tope de filas y el orden', () async {
      for (var i = 0; i < 5; i++) {
        await db.enqueue(
          _action('id$i', createdAt: DateTime.utc(2026, 1, 1 + i)),
        );
      }
      final rows = await db.watchQueue(limit: 3).first;
      expect(rows.map((r) => r.id), ['id4', 'id3', 'id2']);
      expect(AppDatabase.queueWatchLimit, 200);
    });

    test('pendingPhotoRows(limit) acota el lote', () async {
      for (final id in ['p1', 'p2', 'p3']) {
        await db.enqueuePhoto(
          PendingPhotosCompanion.insert(
            id: id,
            shipmentId: 's1',
            filePath: '/tmp/$id.jpg',
          ),
        );
      }
      final rows = await db.pendingPhotoRows(limit: 2);
      expect(rows.map((r) => r.id), ['p1', 'p2']);
    });
  });

  group('OfflineQueue.drain por lotes', () {
    late ProviderContainer container;

    OfflineQueue build(_FakeExecution exec) {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          logisticsApiProvider.overrideWithValue(_FakeApi(exec)),
        ],
      );
      return container.read(offlineQueueProvider);
    }

    tearDown(() => container.dispose());

    Future<void> seed(int count) async {
      for (var i = 0; i < count; i++) {
        await db.enqueue(
          _action(
            'id${i.toString().padLeft(3, '0')}',
            payload: jsonEncode({..._scanPayload(), 'unit_id': 'u$i'}),
          ),
        );
      }
    }

    test('drena más de un lote (60 filas) en orden y vacía la cola', () async {
      final exec = _FakeExecution();
      final queue = build(exec);
      await seed(60);
      await queue.drain();
      expect(exec.keys, hasLength(60));
      expect(exec.keys.first, 'id000');
      expect(exec.keys.last, 'id059');
      expect(await db.countPendingActions(), 0);
    });

    test('pendingCount usa el conteo de la base', () async {
      final queue = build(_FakeExecution());
      await seed(3);
      expect(await queue.pendingCount(), 3);
    });

    test('dos drain simultáneos no reenvían la misma fila', () async {
      final gate = Completer<void>();
      final exec = _FakeExecution(gate: gate);
      final queue = build(exec);
      await seed(3);

      final first = queue.drain();
      final second = queue.drain();
      gate.complete();
      await Future.wait([first, second]);

      expect(exec.keys, ['id000', 'id001', 'id002']);
      expect(await db.countPendingActions(), 0);
    });

    test(
      'una fila encolada durante el drenado se sube en la repasada',
      () async {
        final gate = Completer<void>();
        final exec = _FakeExecution(gate: gate);
        final queue = build(exec);
        await seed(1);

        final first = queue.drain();
        await db.enqueue(_action('id999'));
        final second = queue.drain(); // pide repasar al terminar
        gate.complete();
        await Future.wait([first, second]);

        expect(exec.keys, containsAll(<String>['id000', 'id999']));
        expect(await db.countPendingActions(), 0);
      },
    );

    test('un payload corrupto se aísla como failed y sigue', () async {
      final exec = _FakeExecution();
      final queue = build(exec);
      await db.enqueue(_action('a', payload: '{no-json'));
      await db.enqueue(_action('b'));
      await queue.drain();
      expect(exec.keys, ['b']);
      final rows = await db.select(db.outboxActions).get();
      expect(rows.single.id, 'a');
      expect(rows.single.status, 'failed');
    });
  });
}
