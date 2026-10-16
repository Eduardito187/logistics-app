import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/recent_refuels.dart';

import '../support/driver_test_support.dart';

// Cargas de combustible recientes del vehículo.

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('lista las cargas con litros y total', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleRefuelsProvider.overrideWith(
          (ref) async => [buildRefuel(liters: 40, totalCostCents: 15000)],
        ),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: RecentRefuels()),
      ),
    );

    expect(find.text('Cargas recientes'), findsOneWidget);
    expect(find.text('40.00 L · BOB 150.00'), findsOneWidget);
    // Subtítulo con el tipo de combustible en español.
    expect(find.textContaining('Diésel'), findsOneWidget);
  });

  testWidgets('sin cargas muestra el estado vacío', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleRefuelsProvider.overrideWith((ref) async => <Refuel>[]),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: RecentRefuels()),
      ),
    );
    expect(find.text('Sin cargas registradas'), findsOneWidget);
  });
}
