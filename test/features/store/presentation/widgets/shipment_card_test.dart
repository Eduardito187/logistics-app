import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node_type.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_status_pill.dart';

import '../../store_fixtures.dart';

// Tarjeta de un envío en la lista de recepción. El destino se rotula "tienda" o
// "nodo" según el tipo de nodo.

void main() {
  testWidgets('nodo tienda: rotula "Recibir en tienda" con cliente e ítems', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShipmentCard(
            shipment: shipment(customerName: 'Ana Pérez', lines: 3),
            node: storeNode(name: 'Tienda Centro', type: NodeType.store),
          ),
        ),
      ),
    );

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Pedido DM-260012345  ·  3 ítems'), findsOneWidget);
    expect(find.text('Recibir en tienda · Tienda Centro'), findsOneWidget);
    expect(find.byType(ShipmentStatusPill), findsOneWidget);
  });

  testWidgets('nodo CD: rotula "Recibir en nodo"', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShipmentCard(
            shipment: shipment(),
            node: originNode(name: 'CD Santa Cruz'),
          ),
        ),
      ),
    );

    expect(find.text('Recibir en nodo · CD Santa Cruz'), findsOneWidget);
  });
}
