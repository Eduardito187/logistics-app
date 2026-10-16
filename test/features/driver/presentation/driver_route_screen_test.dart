import 'package:flutter/material.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/driver_route_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_list.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_summary.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_card.dart';

import '../support/driver_test_support.dart';

// Pantalla "Mi ruta de hoy": resumen + mapa/lista de paradas y estados.

void main() {
  testWidgets('sin paradas muestra el estado vacío con "Armar ruta del día"', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        route: buildRoute(
          status: DriverRouteStatus.planned,
          totalStops: 0,
          completedStops: 0,
          stopsRemaining: 0,
          stops: const [],
        ),
      ),
      child: const DriverRouteScreen(),
    );

    expect(find.text('Sin paradas'), findsOneWidget);
    expect(find.text('Armar ruta del día'), findsWidgets);
  });

  testWidgets('con paradas muestra el resumen y la lista al alternar vista', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        route: buildRoute(
          totalStops: 2,
          completedStops: 1,
          stopsRemaining: 1,
          stops: [
            buildStop(id: 'a', sequence: 1, customerName: 'Uno'),
            buildStop(
              id: 'b',
              sequence: 2,
              customerName: 'Dos',
              status: DriverRouteStopStatus.completed,
            ),
          ],
        ),
      ),
      child: const DriverRouteScreen(),
    );

    expect(find.byType(RouteSummary), findsOneWidget);
    expect(find.text('1/2 entregadas · 1 por hacer'), findsOneWidget);

    // Alternar a la vista de lista.
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();

    expect(find.byType(RouteList), findsOneWidget);
    expect(find.byType(StopCard), findsNWidgets(2));
  });

  testWidgets('en error muestra el estado de carga con reintento', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        truckTrackingProvider.overrideWith(FakeTruckTracking.new),
        myCrewProvider.overrideWith((ref) async => buildMyCrew()),
        driverRouteProvider.overrideWith(
          (ref) async => throw const ApiException(status: 500, title: 'x'),
        ),
      ],
      child: const DriverRouteScreen(),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
