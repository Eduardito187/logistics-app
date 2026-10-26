import 'package:logistics_app/core/api/models/address_confidence_level.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/node_reception_view_corridor.dart';
import 'package:logistics_app/core/api/models/node_reception_view_status.dart';
import 'package:logistics_app/core/api/models/node_status.dart';
import 'package:logistics_app/core/api/models/node_type.dart';
import 'package:logistics_app/core/api/models/order_source.dart';
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

/// Bulto esperado del envío.
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
