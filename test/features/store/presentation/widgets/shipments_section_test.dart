import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipments_section.dart';

import '../../store_fixtures.dart';

// Sección con los envíos que llegan al nodo: datos, vacío y error.

Future<void> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storeShipmentsProvider.overrideWith((ref) => load())],
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [ShipmentsSection(node: storeNode())],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con envíos renderiza una tarjeta por envío', (tester) async {
    await _pump(
      tester,
      () async => [shipment(), shipment(id: 'ship-2', customerName: 'Luis')],
    );

    expect(find.text('Envíos'), findsOneWidget);
    expect(find.byType(ShipmentCard), findsNWidgets(2));
  });

  testWidgets('sin envíos muestra "Sin envíos"', (tester) async {
    await _pump(tester, () async => const <Shipment>[]);
    expect(find.text('Sin envíos'), findsOneWidget);
    expect(find.byType(ShipmentCard), findsNothing);
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      () async => throw const ApiException(status: 503, title: 'Caído'),
    );
    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
