import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_points.dart';

import '../support/driver_test_support.dart';

// Derivados de la ruta memoizados por instancia: el GPS reconstruye seguido y
// no debe volver a convertir/simplificar/ordenar 1000+ puntos en cada fix.

RouteGeometry _geometry() => RouteGeometry(
  type: RouteGeometryType.lineString,
  coordinates: [
    for (var i = 0; i <= 1000; i++) [-63.190 + i * 0.00001, -17.790],
  ],
  distanceMeters: 1100,
  durationSeconds: 200,
);

void main() {
  test('la geometría se convierte una vez por instancia', () {
    final geometry = _geometry();
    final first = routeGeometryPoints(geometry);
    expect(first, hasLength(1001));
    expect(identical(routeGeometryPoints(geometry), first), isTrue);
    // Otra instancia (ruta refrescada) se recalcula.
    expect(identical(routeGeometryPoints(_geometry()), first), isFalse);
    // Solo lectura: nadie puede alterar la caché compartida.
    expect(() => first.add(first.first), throwsUnsupportedError);
  });

  test('el trazo simplificado se calcula una vez y es mucho más corto', () {
    final geometry = _geometry();
    final simple = simplifiedRoutePoints(geometry);
    expect(simple, hasLength(2)); // una recta: solo los extremos
    expect(identical(simplifiedRoutePoints(geometry), simple), isTrue);
    expect(simplifiedRoutePoints(null), isEmpty);
  });

  test('precarga y paradas ordenadas memoizadas por ruta', () {
    final route = buildRoute(
      stops: [
        buildStop(id: 'b', sequence: 2, lat: -17.79, lng: -63.18),
        buildStop(id: 'a', sequence: 1),
      ],
      routeGeometry: _geometry(),
    );
    final prefetch = routePrefetchPoints(route);
    // 1 parada con coordenadas + el trazo completo (sin simplificar).
    expect(prefetch, hasLength(1 + 1001));
    expect(identical(routePrefetchPoints(route), prefetch), isTrue);

    final sorted = sortedStops(route);
    expect(sorted.map((s) => s.id), ['a', 'b']);
    expect(identical(sortedStops(route), sorted), isTrue);
    // La lista original de la ruta no se reordena.
    expect(route.stops.first.id, 'b');
  });
}
