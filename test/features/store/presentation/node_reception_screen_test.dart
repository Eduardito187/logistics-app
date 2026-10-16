import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/node_reception_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipments_section.dart';
import 'package:logistics_app/features/store/presentation/widgets/store_selector.dart';

import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Entrada del flujo de recepción: elegir tienda y ver sus envíos. Sin tienda
// elegida se pide seleccionar; con tienda se listan los envíos (o su vacío).

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<Node> nodes,
  required List<Shipment> shipments,
  Node? selected,
}) async {
  final container = ProviderContainer(
    overrides: [
      ...syncBadgeOverrides(),
      storeNodesProvider.overrideWith((ref) async => nodes),
      storeShipmentsProvider.overrideWith((ref) async => shipments),
    ],
  );
  addTearDown(container.dispose);
  if (selected != null) {
    container.read(selectedStoreNodeProvider.notifier).select(selected);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: NodeReceptionScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('sin tienda elegida pide seleccionar el nodo', (tester) async {
    await _pump(tester, nodes: [storeNode()], shipments: [shipment()]);

    expect(find.byType(StoreSelector), findsOneWidget);
    expect(find.text('Elige tu tienda'), findsOneWidget);
    expect(find.byType(ShipmentsSection), findsNothing);
  });

  testWidgets('con tienda elegida lista los envíos que llegan', (tester) async {
    final node = storeNode();
    await _pump(
      tester,
      nodes: [node, originNode()],
      shipments: [shipment(customerName: 'Ana Pérez')],
      selected: node,
    );

    expect(find.byType(ShipmentsSection), findsOneWidget);
    expect(find.byType(ShipmentCard), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
  });

  testWidgets('con tienda elegida pero sin envíos muestra "Sin envíos"', (
    tester,
  ) async {
    final node = storeNode();
    await _pump(tester, nodes: [node], shipments: const [], selected: node);

    expect(find.text('Sin envíos'), findsOneWidget);
    expect(find.byType(ShipmentCard), findsNothing);
  });
}
