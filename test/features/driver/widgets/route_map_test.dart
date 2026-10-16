import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_map.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_pin.dart';

import '../support/driver_test_support.dart';

// Mapa OSM con las paradas como marcadores.

void main() {
  testWidgets('sin coordenadas muestra el estado vacío', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteMap(
          route: buildRoute(stops: [buildStop(lat: null, lng: null)]),
        ),
      ),
    );

    expect(find.text('Sin ubicaciones'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('con coordenadas dibuja el mapa y un pin por parada', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteMap(
          route: buildRoute(
            stops: [
              buildStop(id: 'a', sequence: 1, lat: -16.5, lng: -68.1),
              buildStop(id: 'b', sequence: 2, lat: -16.51, lng: -68.12),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(StopPin), findsNWidgets(2));
  });
}
