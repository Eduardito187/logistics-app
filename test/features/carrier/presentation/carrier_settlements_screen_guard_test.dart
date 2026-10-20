import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_settlements_screen.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';

import '../carrier_fixtures.dart';

// Complementa carrier_settlements_screen_test.dart (que cubre datos y vacío con
// transportista elegido): aquí el guard sin elegir, el error de lista y las
// acciones de la AppBar.

void main() {
  testWidgets('sin transportista elegido el guard pide elegir uno', (
    tester,
  ) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        carriersListProvider.overrideWith((ref) async => [carrier()]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarrierSettlementsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elige tu transportista'), findsOneWidget);
    // Sin transportista elegido no hay acciones de tarifas/cambio en la AppBar.
    expect(find.byTooltip('Ver tarifas'), findsNothing);
    expect(find.byTooltip('Cambiar transportista'), findsNothing);
  });

  testWidgets(
    'con transportista elegido aparecen las acciones y "cambiar" limpia',
    (tester) async {
      final c = carrier();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          carrierSettlementsProvider(
            c.id,
          ).overrideWith((ref) async => <Settlement>[]),
        ],
      );
      addTearDown(container.dispose);
      container.read(selectedCarrierProvider.notifier).select(c);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CarrierSettlementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Ver tarifas'), findsOneWidget);
      expect(find.byTooltip('Cambiar transportista'), findsOneWidget);

      await tester.tap(find.byTooltip('Cambiar transportista'));
      await tester.pumpAndSettle();

      expect(container.read(selectedCarrierProvider), isNull);
    },
  );

  testWidgets('error al listar liquidaciones muestra el estado de error', (
    tester,
  ) async {
    final c = carrier();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        carrierSettlementsProvider(c.id).overrideWith(
          (ref) async => throw const ApiException(status: 500, title: 'Error'),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedCarrierProvider.notifier).select(c);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarrierSettlementsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
