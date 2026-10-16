import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/recent_readings.dart';

import '../support/driver_test_support.dart';

// Lecturas de odómetro recientes del vehículo.

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('lista las lecturas con sus kilómetros', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleOdometerReadingsProvider.overrideWith(
          (ref) async => [buildReading(km: 500)],
        ),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: RecentReadings()),
      ),
    );

    expect(find.text('Lecturas recientes'), findsOneWidget);
    expect(find.text('500 km'), findsOneWidget);
  });

  testWidgets('sin lecturas muestra el estado vacío', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleOdometerReadingsProvider.overrideWith(
          (ref) async => <OdometerReading>[],
        ),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: RecentReadings()),
      ),
    );
    expect(find.text('Sin lecturas registradas'), findsOneWidget);
  });
}
