import 'package:logistics_app/core/api/models/address_confidence_level.dart';
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/delivery_status.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/node_reception_view_corridor.dart';
import 'package:logistics_app/core/api/models/node_reception_view_status.dart';
import 'package:logistics_app/core/api/models/node_status.dart';
import 'package:logistics_app/core/api/models/node_type.dart';
import 'package:logistics_app/core/api/models/order_source.dart';
import 'package:logistics_app/core/api/models/scan_event.dart';
import 'package:logistics_app/core/api/models/scan_type.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_line.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/api/models/unit_status.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';

// Fixtures compartidos del feature Tienda. Construidos a mano con los modelos
// del contrato OpenAPI; ningún test toca Dio ni la red.

/// Nodo de tienda destino (la "tienda" elegida en el selector).
Node storeNode({
  String id = 'node-store',
  String code = 'ST-01',
  String name = 'Tienda Centro',
  NodeType type = NodeType.store,
}) => Node(
  id: id,
  code: code,
  name: name,
  type: type,
  lat: -16.5,
  lng: -68.1,
  status: NodeStatus.active,
);

/// Nodo de origen (CD) para abrir una recepción.
Node originNode({
  String id = 'node-cd',
  String code = 'CD-SCZ',
  String name = 'CD Santa Cruz',
}) => Node(
  id: id,
  code: code,
  name: name,
  type: NodeType.distributionCenter,
  lat: -17.7,
  lng: -63.1,
  status: NodeStatus.active,
);

/// Envío de ejemplo para recepción y entrega en mostrador.
Shipment shipment({
  String id = 'ship-1',
  String externalId = 'DM-260012345',
  String customerName = 'Ana Pérez',
  ShipmentStatus status = ShipmentStatus.inExecution,
  String? customerDocumentId = '12345678',
  String? customerPhone,
  int lines = 2,
}) => Shipment(
  id: id,
  source: OrderSource.sap,
  externalId: externalId,
  customerName: customerName,
  customerDocumentId: customerDocumentId,
  customerPhone: customerPhone,
  addressText: 'Av. Siempre Viva 123',
  addressConfidenceScore: 90,
  addressConfidenceLevel: AddressConfidenceLevel.high,
  status: status,
  lines: [
    for (var i = 0; i < lines; i++)
      ShipmentLine(
        id: 'line-$i',
        sku: 'SKU-$i',
        productName: 'Producto $i',
        quantity: 1,
      ),
  ],
);

/// Producto esperado del envío.
UnitTracking unit({
  String unitId = 'unit-1',
  String shipmentId = 'ship-1',
  String? label,
  String? sku,
  String? productName,
  String? productImageUrl,
}) => UnitTracking(
  id: 'tracking-$unitId',
  unitId: unitId,
  shipmentId: shipmentId,
  status: UnitStatus.registered,
  lastLocationId: null,
  lastSeenAt: null,
  label: label,
  sku: sku,
  productName: productName,
  productImageUrl: productImageUrl,
);

/// Escaneo registrado en el servidor (insumo de [delivery]).
ScanEvent scanEvent({
  String id = 'scan-1',
  String deliveryId = 'delivery-1',
  String unitId = 'unit-1',
  ScanType type = ScanType.proofOfDelivery,
}) => ScanEvent(
  id: id,
  deliveryId: deliveryId,
  type: type,
  unitId: unitId,
  lat: -17.78,
  lng: -63.18,
  deviceId: 'device-1',
  userId: 'user-1',
  occurredAt: DateTime(2026, 3, 1, 11),
  idempotencyKey: 'idem-$id',
);

/// Estado de la entrega de un envío tal como lo devuelve el servidor.
///
/// [podUnitIds] son los productos con prueba de entrega ya confirmada (lo que
/// siembra el POD de mostrador); [otherUnitIds] son escaneos de otro tipo
/// (carga/descarga), que NO son entregas.
Delivery delivery({
  String id = 'delivery-1',
  String shipmentId = 'ship-1',
  DeliveryStatus status = DeliveryStatus.inTransit,
  List<String> podUnitIds = const [],
  List<String> otherUnitIds = const [],
  String? podConfirmation,
}) => Delivery(
  id: id,
  shipmentId: shipmentId,
  vehicleId: 'vehicle-1',
  status: status,
  podConfirmation: podConfirmation,
  scans: [
    for (final unitId in podUnitIds)
      scanEvent(id: 'pod-$unitId', deliveryId: id, unitId: unitId),
    for (final unitId in otherUnitIds)
      scanEvent(
        id: 'load-$unitId',
        deliveryId: id,
        unitId: unitId,
        type: ScanType.load,
      ),
  ],
);

/// Vista de una recepción en un nodo.
NodeReceptionView reception({
  String shipmentId = 'ship-1',
  String originNodeId = 'node-cd',
  String destinationNodeId = 'node-store',
  NodeReceptionViewStatus status = NodeReceptionViewStatus.open,
  List<String> expected = const ['unit-1', 'unit-2'],
  List<String> received = const ['unit-1'],
  List<String> missing = const ['unit-2'],
  List<String> surplus = const [],
}) => NodeReceptionView(
  id: 'reception-1',
  shipmentId: shipmentId,
  originNodeId: originNodeId,
  destinationNodeId: destinationNodeId,
  corridor: NodeReceptionViewCorridor.cdToStore,
  status: status,
  expectedUnitIds: expected,
  receivedUnitIds: received,
  missingUnitIds: missing,
  surplusUnitIds: surplus,
  expectedCount: expected.length,
  receivedCount: received.length,
  complete: missing.isEmpty && surplus.isEmpty,
  openedAt: DateTime(2026, 3, 1, 9),
  reconciledAt: status == NodeReceptionViewStatus.reconciled
      ? DateTime(2026, 3, 1, 10)
      : null,
);
