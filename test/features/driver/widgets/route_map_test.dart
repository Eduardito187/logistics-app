import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
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
    // Sin geometría del backend igual traza la ruta entre paradas.
    final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(layer.polylines.single.points, hasLength(2));
    expect(find.byTooltip('Acercar'), findsOneWidget);
    expect(find.byTooltip('Alejar'), findsOneWidget);
    expect(find.byTooltip('Ver toda la ruta'), findsOneWidget);
  });

  testWidgets('dibuja el trazo por calles del plan y el zoom responde', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteMap(
          route: buildRoute(
            stops: [
              buildStop(id: 'a', sequence: 1, lat: -17.78, lng: -63.18),
              buildStop(id: 'b', sequence: 2, lat: -17.79, lng: -63.19),
            ],
            routeGeometry: const RouteGeometry(
              type: RouteGeometryType.lineString,
              coordinates: [
                [-63.18, -17.78],
                [-63.185, -17.78],
                [-63.185, -17.79],
                [-63.19, -17.79],
              ],
              distanceMeters: 2000,
              durationSeconds: 400,
            ),
          ),
        ),
      ),
    );

    final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(layer.polylines.single.points, hasLength(4));

    final controller = MapController.maybeOf(
      tester.element(find.byType(MarkerLayer)),
    )!;
    final before = controller.camera.zoom;
    await tester.tap(find.byTooltip('Acercar'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, closeTo(before + 1, 1e-6));
  });
}
