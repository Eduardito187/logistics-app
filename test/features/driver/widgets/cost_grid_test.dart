import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/cost_grid.dart';

import '../support/driver_test_support.dart';

// Rejilla de costos del vehículo (TCO, costo/km, combustible, etc.).

void main() {
  testWidgets('formatea cada métrica de costo', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(body: CostGrid(buildCostSummary(costPerKmCents: 500))),
    );

    expect(find.text('Costo total'), findsOneWidget);
    expect(find.text('BOB 1700.00'), findsOneWidget);
    expect(find.text('Costo por km'), findsOneWidget);
    expect(find.text('BOB 5.00'), findsOneWidget);
    expect(find.text('Combustible'), findsOneWidget);
    expect(find.text('BOB 1000.00'), findsOneWidget);
    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.text('BOB 500.00'), findsOneWidget);
    expect(find.text('Otros gastos'), findsOneWidget);
    expect(find.text('BOB 200.00'), findsOneWidget);
    expect(find.text('Recorrido'), findsOneWidget);
    expect(find.text('1200 km'), findsOneWidget);
  });

  testWidgets('costo por km nulo muestra "—"', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(body: CostGrid(buildCostSummary(costPerKmCents: null))),
    );
    expect(find.text('—'), findsOneWidget);
  });
}
