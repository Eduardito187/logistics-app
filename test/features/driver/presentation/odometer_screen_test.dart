import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/odometer_screen.dart';

import '../support/driver_test_support.dart';
import '../../../support/button_finders.dart';

// Registro de odómetro.
//
// FALENCIA DETECTADA: OdometerScreen._submit llama directamente a
// `ref.read(logisticsApiProvider)` (lib/features/driver/presentation/odometer_screen.dart:102),
// violando la regla 5 de docs/clean-architecture.md y dejando la ruta de éxito
// sin seam para test. Se prueban las validaciones previas a la red.

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  List<Object> overridesFor() => [
    ...gateBase(),
    vehicleOdometerReadingsProvider.overrideWith(
      (ref) async => <OdometerReading>[],
    ),
  ];

  testWidgets('render del formulario de nueva lectura', (tester) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const OdometerScreen(),
      tall: true,
    );

    expect(find.text('Odómetro'), findsWidgets);
    expect(find.text('Nueva lectura'), findsOneWidget);
    expect(find.text('Registrar lectura'), findsOneWidget);
  });

  testWidgets('sin kilómetros avisa que faltan', (tester) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const OdometerScreen(),
      tall: true,
    );

    await tester.tap(findButtonWithText<FilledButton>('Registrar lectura'));
    await tester.pump();

    expect(find.text('Ingresa los kilómetros actuales.'), findsOneWidget);
  });

  testWidgets('kilómetros en cero se rechazan', (tester) async {
    await pumpScoped(
      tester,
      overrides: overridesFor(),
      child: const OdometerScreen(),
      tall: true,
    );

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(findButtonWithText<FilledButton>('Registrar lectura'));
    await tester.pump();

    expect(find.text('Ingresa los kilómetros actuales.'), findsOneWidget);
  });
}
