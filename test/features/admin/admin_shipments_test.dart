import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/admin/presentation/admin_shipments_screen.dart';

import 'fake_admin.dart';

// Envíos del administrador: ciudad y estado se ELIGEN (no se escriben), y el
// detalle muestra la foto del producto, el SKU sin prefijo y, si el pedido se
// entregó, con qué evidencia.

Shipment _shipment(
  ShipmentStatus status, {
  ShipmentDeliveryEvidence? evidence,
}) => Shipment(
  deliveryEvidence: evidence,
  id: 'ship-1',
  source: OrderSource.sap,
  externalId: 'SO-900001',
  customerName: 'María Quispe',
  addressText: 'Av. 6 de Agosto 2170, La Paz',
  addressConfidenceScore: 80,
  addressConfidenceLevel: AddressConfidenceLevel.high,
  status: status,
  lines: const [
    ShipmentLine(
      id: 'l1',
      sku: 'COL-QUEEN',
      productName: 'Colchón Queen',
      quantity: 2,
    ),
  ],
);

void main() {
  testWidgets('la ciudad se elige de una lista y filtra en el servidor', (
    tester,
  ) async {
    final fake = FakeAdmin(shipments: [_shipment(ShipmentStatus.planned)]);
    await pumpAdmin(tester, fake, const AdminShipmentsScreen());

    await tester.tap(find.text('Todas las ciudades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('La Paz').last);
    await tester.pumpAndSettle();

    expect(fake.shipmentFilters.last.city, 'la_paz');
  });

  testWidgets('el estado se elige de una lista', (tester) async {
    final fake = FakeAdmin(shipments: [_shipment(ShipmentStatus.planned)]);
    await pumpAdmin(tester, fake, const AdminShipmentsScreen());

    await tester.tap(find.text('Todos los estados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entregados').last);
    await tester.pumpAndSettle();

    expect(fake.shipmentFilters.last.status, ShipmentStatus.delivered);
  });

  testWidgets('detalle: SKU sin prefijo y acciones si el pedido está abierto', (
    tester,
  ) async {
    final fake = FakeAdmin(shipments: [_shipment(ShipmentStatus.planned)]);
    await pumpAdmin(tester, fake, const AdminShipmentsScreen());

    await tester.tap(find.text('Pedido SO-900001'));
    await tester.pumpAndSettle();

    expect(find.text('COL-QUEEN'), findsOneWidget);
    expect(find.textContaining('SKU'), findsNothing);
    expect(find.text('Asignar a un camión'), findsOneWidget);
    expect(find.text('Firma digital'), findsNothing);
  });

  testWidgets('detalle de un entregado: dice cómo se entregó', (tester) async {
    final fake = FakeAdmin(
      shipments: [
        _shipment(
          ShipmentStatus.delivered,
          evidence: const ShipmentDeliveryEvidence(
            signature: true,
            photo: true,
            document: false,
            withShortage: false,
          ),
        ),
      ],
    );
    await pumpAdmin(tester, fake, const AdminShipmentsScreen());

    await tester.tap(find.text('Pedido SO-900001'));
    await tester.pumpAndSettle();

    expect(find.text('Firma digital'), findsOneWidget);
    expect(find.text('Foto de entrega'), findsOneWidget);
    expect(find.text('Foto de documento'), findsNothing);
    expect(find.text('Asignar a un camión'), findsNothing);
  });

  testWidgets('entregado con faltante: tag ámbar con el número', (
    tester,
  ) async {
    final fake = FakeAdmin(
      shipments: [
        _shipment(
          ShipmentStatus.delivered,
          evidence: const ShipmentDeliveryEvidence(
            signature: true,
            photo: true,
            document: false,
            withShortage: true,
            missingCount: 2,
          ),
        ),
      ],
    );
    await pumpAdmin(tester, fake, const AdminShipmentsScreen());

    await tester.tap(find.text('Pedido SO-900001'));
    await tester.pumpAndSettle();

    expect(find.text('Firma digital'), findsOneWidget);
    expect(find.text('Entregado con faltante (2)'), findsOneWidget);
  });
}
