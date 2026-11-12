import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipments_section.dart';

import '../../store_fixtures.dart';
import '../../store_test_harness.dart';

// Sección con los envíos que llegan al nodo: datos, vacío, error y el pie de
// scroll infinito.

Future<FakeStoreShipments> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load, {
  bool hasMore = false,
}) async {
  final notifier = FakeStoreShipments(load, hasMore: hasMore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storeShipmentsPagedProvider.overrideWith(() => notifier)],
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
  return notifier;
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

  testWidgets('sin más páginas no hay pie de "cargar más"', (tester) async {
    await _pump(tester, () async => [shipment()]);
    expect(find.text('Cargar más envíos'), findsNothing);
  });

  testWidgets('con más páginas el pie pide la siguiente', (tester) async {
    final notifier = await _pump(
      tester,
      () async => [shipment()],
      hasMore: true,
    );

    await tester.tap(find.text('Cargar más envíos'));
    await tester.pump();

    expect(notifier.loadMoreCalls, 1);
    expect(find.text('Cargando más envíos…'), findsOneWidget);
  });
}
