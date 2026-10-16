import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/commands/command_feedback.dart';
import 'package:logistics_app/core/commands/command_outcome.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/fuel_screen.dart';

import '../support/driver_test_support.dart';

// Carga de combustible.
//
// FALENCIA DETECTADA: FuelScreen._submit llama directamente a
// `ref.read(logisticsApiProvider)` (lib/features/driver/presentation/fuel_screen.dart:185),
// lo que viola la regla 5 de docs/clean-architecture.md ("Prohibido
// ref.read(logisticsApiProvider) fuera de data/datasources/"). Además deja la
// ruta del 202 async imposible de probar sin un seam de API (no hay caso de uso
// inyectable). Acá se prueban las validaciones que corren ANTES de tocar la red
// y, por separado, el feedback del 202 async vía showCommandOutcome.

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  List<Object> overridesFor() => [
    ...gateBase(),
    currentFuelPriceProvider(FuelType.diesel)
        .overrideWith((ref) async => buildFuelPrice()),
    vehicleRefuelsProvider.overrideWith((ref) async => <Refuel>[]),
  ];

  testWidgets('render: título, tanque lleno por defecto y precio vigente', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const FuelScreen(),
      tall: true,
    );

    expect(find.text('Cargar combustible'), findsWidgets);
    expect(find.text('Registrar carga'), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(sw.value, isTrue); // tanque lleno por defecto
    expect(find.textContaining('Precio vigente:'), findsOneWidget);
  });

  testWidgets('sin litros avisa que faltan los litros', (tester) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const FuelScreen(),
      tall: true,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar carga'));
    await tester.pump();

    expect(find.text('Ingresa los litros cargados.'), findsOneWidget);
  });

  testWidgets('con litros pero sin precio avisa que falta el precio', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const FuelScreen(),
      tall: true,
    );

    await tester.enterText(find.byType(TextField).first, '40');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar carga'));
    await tester.pump();

    expect(find.text('Ingresa el precio por litro.'), findsOneWidget);
  });

  testWidgets('el 202 async (AcceptedEnvelope) se comunica como "Aceptado..." '
      '(feedback que usa FuelScreen)', (tester) async {
    // Documenta el desenlace esperado del 202 que FuelScreen no puede ejercitar
    // en test por llamar directo a la API.
    final outcome = CommandOutcome.fromAccepted(
      const AcceptedEnvelope(data: Data21(accepted: true)),
    );
    expect(outcome.isAccepted, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showCommandOutcome(context, outcome),
              child: const Text('x'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pump();

    expect(find.text('Aceptado. Se está procesando.'), findsOneWidget);
  });
}
