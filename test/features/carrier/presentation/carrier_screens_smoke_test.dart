import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_assignment_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_cheapest_tariff_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_tariff_screen.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_form.dart';

import '../carrier_fixtures.dart';

// Pantallas contenedoras del transportista: montan su título y el formulario
// correspondiente. Los formularios no tocan el repositorio hasta consultar, así
// que renderizan sin overrides.

void main() {
  testWidgets('pantalla de asignación muestra título y formulario', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CarrierAssignmentScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asignación por volumen'), findsOneWidget);
    expect(find.byType(AssignmentForm), findsOneWidget);
  });

  testWidgets('pantalla de tarifa más barata muestra título y formulario', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CarrierCheapestTariffScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tarifa más barata'), findsOneWidget);
    expect(find.byType(CheapestTariffForm), findsOneWidget);
  });

  testWidgets('pantalla de tarifas (con transportista) muestra el formulario', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedCarrierProvider.notifier).select(carrier());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarrierTariffScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tarifas por corredor'), findsOneWidget);
    expect(find.byType(TariffForm), findsOneWidget);
    expect(find.byTooltip('Asignación por volumen'), findsOneWidget);
    expect(find.byTooltip('Tarifa más barata'), findsOneWidget);
  });
}
