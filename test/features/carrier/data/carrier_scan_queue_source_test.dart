import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/features/carrier/data/datasources/carrier_scan_queue_source.dart';
import 'package:logistics_app/features/carrier/domain/models/carrier_scan_kind.dart';

// Reconstrucción de la tanda del transportista desde la cola offline: se leen
// SOLO sus filas pendientes (la cola es del dispositivo y el chofer y la tienda
// encolan con el mismo `kind`).

void main() {
  late AppDatabase db;
  late CarrierScanQueueSource source;

  setUp(() {
    // Base en memoria (requiere la lib nativa sqlite3, estándar en Drift).
    db = AppDatabase(NativeDatabase.memory());
    source = CarrierScanQueueSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> enqueue({
    required String id,
    required String kind,
    required String unitId,
    required String label,
    String status = 'pending',
    DateTime? createdAt,
  }) {
    return db.enqueue(
      OutboxActionsCompanion.insert(
        id: id,
        kind: kind,
        payload: jsonEncode({'unit_id': unitId, 'shipment_id': 'DM-1'}),
        occurredAt: DateTime.utc(2026, 11, 12, 9),
        status: Value(status),
        label: Value(label),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );
  }

  test('recojos pendientes del transportista, el último primero', () async {
    await enqueue(
      id: '1',
      kind: 'recordLoadScan',
      unitId: 'U-A',
      label: CarrierScanKind.pickup.labelFor('SKU-A'),
      createdAt: DateTime.utc(2026, 11, 12, 9),
    );
    await enqueue(
      id: '2',
      kind: 'recordLoadScan',
      unitId: 'U-B',
      label: CarrierScanKind.pickup.labelFor('SKU-B'),
      createdAt: DateTime.utc(2026, 11, 12, 10),
    );

    final scans = await source.pending(CarrierScanKind.pickup);

    expect(scans.map((s) => s.unitId), ['U-B', 'U-A']);
    expect(scans.first.sku, 'SKU-B');
    // Drift devuelve la hora en local: se compara el instante.
    expect(
      scans.first.at.isAtSameMomentAs(DateTime.utc(2026, 11, 12, 9)),
      isTrue,
    );
  });

  test('no mezcla las filas del chofer ni de la tienda (mismo kind)', () async {
    // Chofer: carga del camión, mismo `kind` que el recojo del transportista.
    await enqueue(
      id: '1',
      kind: 'recordLoadScan',
      unitId: 'U-DRIVER',
      label: 'Carga · U-DRIVER',
    );
    // Tienda: POD de mostrador, mismo `kind` que la entrega del transportista.
    await enqueue(
      id: '2',
      kind: 'recordProofOfDelivery',
      unitId: 'U-STORE',
      label: 'Entrega · Juan Pérez',
    );
    await enqueue(
      id: '3',
      kind: 'recordProofOfDelivery',
      unitId: 'U-CARRIER',
      label: CarrierScanKind.deliver.labelFor('SKU-C'),
    );

    expect(await source.pending(CarrierScanKind.pickup), isEmpty);
    final delivers = await source.pending(CarrierScanKind.deliver);
    expect(delivers.map((s) => s.unitId), ['U-CARRIER']);
    expect(delivers.single.sku, 'SKU-C');
  });

  test('ignora las filas fallidas y las de payload ilegible', () async {
    await enqueue(
      id: '1',
      kind: 'recordLoadScan',
      unitId: 'U-FAILED',
      label: CarrierScanKind.pickup.labelFor('SKU-F'),
      status: 'failed',
    );
    await db.enqueue(
      OutboxActionsCompanion.insert(
        id: '2',
        kind: 'recordLoadScan',
        payload: 'no es json',
        occurredAt: DateTime.utc(2026, 11, 12, 9),
        label: Value(CarrierScanKind.pickup.labelFor('SKU-X')),
      ),
    );
    await db.enqueue(
      OutboxActionsCompanion.insert(
        id: '3',
        kind: 'recordLoadScan',
        payload: jsonEncode({'shipment_id': 'DM-1'}),
        occurredAt: DateTime.utc(2026, 11, 12, 9),
        label: Value(CarrierScanKind.pickup.labelFor('SKU-Y')),
      ),
    );

    expect(await source.pending(CarrierScanKind.pickup), isEmpty);
  });

  test('etiqueta sin el separador esperado: no es nuestra', () async {
    await enqueue(
      id: '1',
      kind: 'recordLoadScan',
      unitId: 'U-A',
      // Mismo comienzo, pero no es "<prefijo> · SKU".
      label: '${CarrierScanKind.pickup.labelPrefix}X-SKU',
    );

    expect(await source.pending(CarrierScanKind.pickup), isEmpty);
  });
}
