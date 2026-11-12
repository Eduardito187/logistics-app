import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';
import 'package:logistics_app/features/store/presentation/counter_pickup_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';

import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Lista de envíos para entrega en mostrador: estados con datos, vacío y
// error, y el pie de scroll infinito cuando el servidor tiene más páginas.

Future<FakeStoreShipments> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load, {
  bool hasMore = false,
}) async {
  final notifier = FakeStoreShipments(load, hasMore: hasMore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        storeShipmentsPagedProvider.overrideWith(() => notifier),
      ],
      child: const MaterialApp(home: CounterPickupScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  testWidgets('con datos muestra una tarjeta por envío', (tester) async {
    await _pump(
      tester,
      () async => [
        shipment(customerName: 'Ana Pérez'),
        shipment(id: 'ship-2', customerName: 'Luis Gómez'),
      ],
    );

    expect(find.text('Recojo en tienda'), findsOneWidget);
    expect(find.byType(PickupCard), findsNWidgets(2));
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('sin envíos muestra el estado vacío "Sin recojos"', (
    tester,
  ) async {
    await _pump(tester, () async => const <Shipment>[]);

    expect(find.text('Sin recojos'), findsOneWidget);
    expect(find.byType(PickupCard), findsNothing);
  });

  testWidgets('error de API muestra el estado de error con reintento', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => throw const ApiException(
        status: 500,
        title: 'Error',
        detail: 'Servidor no disponible',
      ),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('sin más páginas no hay pie de "cargar más"', (tester) async {
    await _pump(tester, () async => [shipment()]);

    expect(find.text('Cargar más recojos'), findsNothing);
  });

  testWidgets('con más páginas el pie pide la siguiente y avisa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notifier = await _pump(
      tester,
      () async => [shipment(), shipment(id: 'ship-2')],
      hasMore: true,
    );

    await tester.tap(find.text('Cargar más recojos'));
    await tester.pump();

    expect(notifier.loadMoreCalls, 1);
    expect(find.text('Cargando más recojos…'), findsOneWidget);
    expect(find.text('Cargar más recojos'), findsNothing);
  });

  testWidgets('llegar al final de la lista pide la página siguiente', (
    tester,
  ) async {
    final notifier = await _pump(
      tester,
      () async => [
        for (var i = 0; i < 20; i++)
          shipment(id: 'ship-$i', customerName: 'Cliente $i'),
      ],
      hasMore: true,
    );
    expect(notifier.loadMoreCalls, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pump();

    expect(notifier.loadMoreCalls, greaterThan(0));
  });
}
