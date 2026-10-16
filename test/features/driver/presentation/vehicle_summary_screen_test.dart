import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/vehicle_summary_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/cost_grid.dart';
import 'package:logistics_app/features/driver/presentation/widgets/utilization_card.dart';

import '../support/driver_test_support.dart';

// Resumen del vehículo: costos (TCO + costo/km) y utilización (30 días).

void main() {
  testWidgets('muestra la rejilla de costos y la utilización', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        ...gateBase(),
        vehicleCostSummaryProvider.overrideWith(
          (ref) async => buildCostSummary(costPerKmCents: 500),
        ),
        vehicleUtilizationProvider.overrideWith(
          (ref) async => <String, Object?>{'active_days': 20},
        ),
      ],
      child: const VehicleSummaryScreen(),
      tall: true,
    );

    expect(find.text('Resumen del vehículo'), findsOneWidget);
    expect(find.byType(CostGrid), findsOneWidget);
    expect(find.text('BOB 1700.00'), findsOneWidget); // costo total
    expect(find.text('BOB 5.00'), findsOneWidget); // costo por km
    expect(find.byType(UtilizationCard), findsOneWidget);
    expect(find.text('active days'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });
}
