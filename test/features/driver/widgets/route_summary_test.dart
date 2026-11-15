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

    expect(find.text('2/5'), findsOneWidget); // centro del anillo
    expect(find.text('2 entregadas'), findsOneWidget);
    expect(find.text('3 por hacer'), findsOneWidget);
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

    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('4 entregadas'), findsOneWidget);
    expect(find.text('0 por hacer'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
  });

  testWidgets(
    'item por item: con una fallida está completa y muestra "no entregadas"',
    (tester) async {
      // Bug del dueño: 6/7 y "completada". Con la fuente única: la ruta ESTÁ
      // completa (sin pendientes), pero el conteo honesto es 6 entregadas + 1
      // no entregada, no 7 entregadas.
      await pumpScoped(
        tester,
        child: Scaffold(
          body: RouteSummary(
            route: buildRoute(
              // Agregados del backend contradictorios a propósito: se ignoran.
              status: DriverRouteStatus.inProgress,
              totalStops: 7,
              completedStops: 7,
              stopsRemaining: 0,
              stops: [
                for (var i = 0; i < 6; i++)
                  buildStop(
                    id: 's$i',
                    sequence: i + 1,
                    status: DriverRouteStopStatus.completed,
                  ),
                buildStop(
                  id: 's6',
                  sequence: 7,
                  status: DriverRouteStopStatus.failed,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('6/7'), findsOneWidget);
      expect(find.text('6 entregadas'), findsOneWidget);
      expect(find.text('1 no entregadas'), findsOneWidget);
      expect(find.text('0 por hacer'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
    },
  );
}
