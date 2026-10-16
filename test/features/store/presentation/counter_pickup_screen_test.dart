import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/counter_pickup_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';

import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Lista de envíos para entrega en mostrador: estados con datos, vacío y error.

Future<void> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        storeShipmentsProvider.overrideWith((ref) => load()),
      ],
      child: const MaterialApp(home: CounterPickupScreen()),
    ),
  );
  await tester.pumpAndSettle();
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

    expect(find.text('Entrega en mostrador'), findsOneWidget);
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
}
