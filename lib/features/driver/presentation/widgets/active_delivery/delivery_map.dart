import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/location/truck_tracking_service.dart';
import '../../../../../core/map/osm_tile_layer.dart';
import '../../../../../core/map/tile_prefetch.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/route_navigation.dart';
import 'map_round_button.dart';

/// Posición del camión: la del rastreo en vivo si está activo; si no, una
/// lectura puntual del GPS al abrir la pantalla.
final deliveryDriverFixProvider = FutureProvider.autoDispose<GpsFix?>((ref) {
  final live = ref.watch(truckTrackingProvider.select((s) => s.lastFix));
  if (live != null) return live;
  return ref.read(locationServiceProvider).current();
});

/// Distancia/tiempo restantes del camión a [stop] y si está fuera de ruta.
/// `null` sin posición del camión o sin coordenadas de la parada.
RemainingEstimate? remainingToStop(
  DriverRoute route,
  DriverRouteStop stop,
  GpsFix? fix,
) {
  if (fix == null || stop.lat == null || stop.lng == null) return null;
  final geometry = route.routeGeometry;
  return estimateRemaining(
    from: LatLng(fix.lat, fix.lng),
    to: LatLng(stop.lat!, stop.lng!),
    geometry: routeGeometryPoints(geometry),
    geometryMeters: geometry?.distanceMeters,
    geometrySeconds: geometry?.durationSeconds,
  );
}

/// Precarga de tiles del mapa (inyectable para tests: sin red ni disco).
typedef RouteTilePrefetcher = Future<void> Function(List<LatLng> points);

/// Al abrir la entrega en curso se precargan los tiles de la ruta (paradas y
/// trazo) para que el mapa se vea aunque después se pierda la señal.
final routeTilePrefetcherProvider = Provider<RouteTilePrefetcher>(
  (ref) =>
      (points) => prefetchRouteTiles(points),
);

/// Puntos a precargar: todas las paradas con coordenadas más el trazo.
List<LatLng> routePrefetchPoints(DriverRoute route) => [
  for (final s in route.stops)
    if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!),
  ...routeGeometryPoints(route.routeGeometry),
];

/// Mapa de la entrega en curso: destino, camión y el trazo, más las paradas
/// siguientes en gris. El trazo es la ruta por calles del plan
/// (`DriverRoute.routeGeometry`); si el backend no la tiene, una línea directa
/// camión → destino.
///
/// Modo "seguir": centra el mapa en el camión cada vez que se mueve; se activa
/// con su botón y se apaga solo al arrastrar el mapa con el dedo.
class DeliveryMap extends ConsumerStatefulWidget {
  const DeliveryMap({super.key, required this.route, required this.stop});

  final DriverRoute route;
  final DriverRouteStop stop;

  @override
  ConsumerState<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends ConsumerState<DeliveryMap> {
  final MapController _controller = MapController();

  /// Modo "seguir al camión".
  bool _follow = false;

  /// Zoom al seguir: suficiente para ver la cuadra siguiente.
  static const double _followZoom = 17;

  @override
  void initState() {
    super.initState();
    final points = routePrefetchPoints(widget.route);
    if (points.isNotEmpty) {
      // Best-effort y sin bloquear la pantalla: un fallo no se muestra.
      unawaited(
        ref.read(routeTilePrefetcherProvider)(points).catchError((Object _) {}),
      );
    }
  }

  /// Espacio que tapan la tarjeta de arriba y la hoja de abajo: el encuadre
  /// deja los puntos visibles en el hueco del medio.
  static const EdgeInsets _fitPadding = EdgeInsets.fromLTRB(48, 260, 48, 300);

  LatLng? get _destination {
    final s = widget.stop;
    return s.lat != null && s.lng != null ? LatLng(s.lat!, s.lng!) : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _followTo(LatLng driver) {
    final zoom = _controller.camera.zoom;
    _controller.move(driver, zoom < _followZoom ? _followZoom : zoom);
  }

  void _toggleFollow(LatLng? driver) {
    setState(() => _follow = !_follow);
    if (_follow && driver != null) _followTo(driver);
  }

  void _recenter(LatLng? driver) {
    final points = [?_destination, ?driver];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.single, 16);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: _fitPadding,
        // Dos puntos iguales (camión en la parada) darían zoom infinito.
        maxZoom: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Al moverse el camión, si está en modo seguir, el mapa lo acompaña.
    ref.listen(deliveryDriverFixProvider, (_, next) {
      final f = next.value;
      if (_follow && f != null) _followTo(LatLng(f.lat, f.lng));
    });
    final fix = ref.watch(deliveryDriverFixProvider).value;
    final driver = fix == null ? null : LatLng(fix.lat, fix.lng);
    final destination = _destination;
    final upcoming = widget.route.stops
        .where(
          (s) =>
              s.id != widget.stop.id &&
              s.status == DriverRouteStopStatus.pending &&
              s.lat != null &&
              s.lng != null,
        )
        .map((s) => LatLng(s.lat!, s.lng!))
        .toList(growable: false);

    final anchor =
        destination ??
        driver ??
        (upcoming.isNotEmpty ? upcoming.first : null) ??
        const LatLng(-17.7833, -63.1821); // Santa Cruz por defecto.
    final scheme = Theme.of(context).colorScheme;
    final streets = routeGeometryPoints(widget.route.routeGeometry);

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: anchor,
            initialZoom: 15,
            initialCameraFit: destination != null && driver != null
                ? CameraFit.coordinates(
                    coordinates: [destination, driver],
                    padding: _fitPadding,
                    maxZoom: 18,
                  )
                : null,
            // Arrastrar el mapa con el dedo apaga el modo seguir.
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            const OsmTileLayer(),
            if (streets.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: streets,
                    strokeWidth: 5,
                    color: scheme.onSurface,
                  ),
                ],
              )
            else if (destination != null && driver != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [driver, destination],
                    strokeWidth: 5,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final p in upcoming)
                  Marker(
                    point: p,
                    width: 18,
                    height: 18,
                    child: const _UpcomingDot(),
                  ),
                if (destination != null)
                  Marker(
                    point: destination,
                    width: 56,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.location_on,
                      size: 56,
                      color: scheme.onSurface,
                      semanticLabel: 'Destino',
                    ),
                  ),
                if (driver != null)
                  Marker(
                    point: driver,
                    width: 44,
                    height: 44,
                    child: const _TruckMarker(),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          // Encima de la hoja colapsada (≈32% del alto).
          bottom: MediaQuery.sizeOf(context).height * 0.32 + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (driver != null) ...[
                MapRoundButton(
                  tooltip: _follow ? 'Dejar de seguir' : 'Seguir camión',
                  icon: _follow ? Icons.navigation : Icons.navigation_outlined,
                  selected: _follow,
                  onPressed: () => _toggleFollow(driver),
                ),
                const SizedBox(height: 10),
              ],
              MapRoundButton(
                tooltip: 'Centrar',
                icon: Icons.my_location,
                onPressed: () => _recenter(driver),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TruckMarker extends StatelessWidget {
  const _TruckMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Icon(
        Icons.local_shipping,
        color: Colors.white,
        size: 22,
        semanticLabel: 'Tu camión',
      ),
    );
  }
}

class _UpcomingDot extends StatelessWidget {
  const _UpcomingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

/// Convierte la geometría GeoJSON del backend (`[lng, lat]`) a puntos del
/// mapa. Ignora pares mal formados. Vacía si no hay geometría.
List<LatLng> routeGeometryPoints(RouteGeometry? geometry) {
  if (geometry == null) return const [];
  return [
    for (final pair in geometry.coordinates)
      if (pair.length >= 2) LatLng(pair[1].toDouble(), pair[0].toDouble()),
  ];
}
