import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../domain/entities/route_navigation.dart';

// Derivados de la ruta del día, calculados UNA vez por instancia de la ruta.
//
// El GPS reconstruye el mapa y la tarjeta de estado cada pocos segundos; la
// geometría puede traer 1000+ puntos. Se memoiza por identidad del objeto
// (`Expando`): mientras el provider devuelva la misma `DriverRoute` se reusa
// la lista; al refrescar la ruta llega un objeto nuevo y se recalcula. El
// `Expando` no retiene la ruta: cuando la ruta se libera, su caché también.

final Expando<List<LatLng>> _geometryPoints = Expando('routeGeometryPoints');
final Expando<List<LatLng>> _simplifiedPoints = Expando('simplifiedRoute');
final Expando<List<LatLng>> _prefetchPoints = Expando('routePrefetchPoints');
final Expando<List<DriverRouteStop>> _sortedStops = Expando('sortedStops');

/// Convierte la geometría GeoJSON del backend (`[lng, lat]`) a puntos del
/// mapa. Ignora pares mal formados. Vacía si no hay geometría. Memoizada por
/// instancia de [geometry]; la lista es de solo lectura.
List<LatLng> routeGeometryPoints(RouteGeometry? geometry) {
  if (geometry == null) return const [];
  return _geometryPoints[geometry] ??= List<LatLng>.unmodifiable(<LatLng>[
    for (final pair in geometry.coordinates)
      if (pair.length >= 2) LatLng(pair[1].toDouble(), pair[0].toDouble()),
  ]);
}

/// Trazo simplificado (Douglas-Peucker, [kRouteSimplifyToleranceMeters]) para
/// dibujar y para estimar lo que falta: mismo recorrido a escala de calle, con
/// muchos menos puntos que proyectar en cada fix del GPS. Memoizado.
List<LatLng> simplifiedRoutePoints(RouteGeometry? geometry) {
  if (geometry == null) return const [];
  return _simplifiedPoints[geometry] ??= List<LatLng>.unmodifiable(
    simplifyPolyline(routeGeometryPoints(geometry)),
  );
}

/// Puntos a precargar: todas las paradas con coordenadas más el trazo
/// completo (sin simplificar: la precarga cubre los tiles alrededor de cada
/// punto y no debe dejar huecos en rectas largas). Memoizado por ruta.
List<LatLng> routePrefetchPoints(DriverRoute route) =>
    _prefetchPoints[route] ??= List<LatLng>.unmodifiable(<LatLng>[
      for (final s in route.stops)
        if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!),
      ...routeGeometryPoints(route.routeGeometry),
    ]);

/// Paradas de la ruta ordenadas por secuencia. Memoizado por ruta (la lista,
/// el mapa y la entrega en curso no reordenan en cada reconstrucción).
List<DriverRouteStop> sortedStops(DriverRoute route) =>
    _sortedStops[route] ??= List<DriverRouteStop>.unmodifiable(
      <DriverRouteStop>[...route.stops]
        ..sort((a, b) => a.sequence.compareTo(b.sequence)),
    );
