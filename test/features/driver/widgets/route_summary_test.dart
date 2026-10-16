import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_summary.dart';

import '../support/driver_test_support.dart';

// Resumen de avance de la ruta: entregadas/total + por hacer + estado.

void main() {
  testWidgets('muestra el avance y el estado en curso', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteSummary(
          route: buildRoute(
            status: DriverRouteStatus.inProgress,
            totalStops: 5,
            completedStops: 2,
            stopsRemaining: 3,
          ),
        ),
      ),
    );

    expect(find.text('2/5 entregadas · 3 por hacer'), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
  });

  testWidgets('ruta completada muestra el estado Completada', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteSummary(
          route: buildRoute(
            status: DriverRouteStatus.completed,
            totalStops: 4,
            completedStops: 4,
            stopsRemaining: 0,
          ),
        ),
      ),
    );

    expect(find.text('4/4 entregadas · 0 por hacer'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
  });
}
