import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../../../core/map/osm_tile_layer.dart';
import '../../../../core/widgets/empty_state.dart';
import '../driver_route_status.dart';
import 'active_delivery/map_round_button.dart';
import 'map_zoom_buttons.dart';
import 'route_points.dart';
import 'stop_pin.dart';

/// Mapa OSM de la ruta del día: el trazo por calles del plan
/// (`DriverRoute.routeGeometry`, simplificado; si no llega, una línea entre las
/// paradas en orden) y las paradas como marcadores tocables. Arranca
/// encuadrando todo el recorrido y tiene botones grandes de acercar/alejar.
///
/// Las capas (trazo y marcadores) se arman una vez por ruta y se reusan como la
/// misma instancia de widget: reconstruir la pantalla (p. ej. el botón "Armar
/// ruta") no vuelve a proyectar los puntos del trazo.
class RouteMap extends StatefulWidget {
  const RouteMap({super.key, required this.route});

  final DriverRoute route;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _controller = MapController();

  static const EdgeInsets _fitPadding = EdgeInsets.all(48);

  // Derivados memoizados de la ruta (y el color con que se pintó el trazo).
  DriverRoute? _cachedRoute;
  Color? _cachedColor;
  List<DriverRouteStop> _located = const [];
  List<LatLng> _fitPoints = const [];
  Widget _lineLayer = const SizedBox.shrink();
  Widget _stopsLayer = const SizedBox.shrink();

  /// Se arman con el primer encuadre: flutter_map solo usa el centro/zoom
  /// iniciales al crear el mapa.
  MapOptions? _options;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureLayers(Color lineColor) {
    if (identical(_cachedRoute, widget.route) && _cachedColor == lineColor) {
      return;
    }
    _cachedRoute = widget.route;
    _cachedColor = lineColor;
    _located = sortedStops(
      widget.route,
    ).where((s) => s.lat != null && s.lng != null).toList(growable: false);
    final stopPoints = [for (final s in _located) LatLng(s.lat!, s.lng!)];
    final streets = simplifiedRoutePoints(widget.route.routeGeometry);
    final line = streets.length >= 2 ? streets : stopPoints;
    _fitPoints = [...stopPoints, ...streets];
    _lineLayer = line.length >= 2
        ? PolylineLayer(
            polylines: [
              Polyline(
                points: line,
                strokeWidth: 5,
                color: lineColor,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          )
        : const SizedBox.shrink();
    _stopsLayer = MarkerLayer(
      markers: [
        for (final stop in _located)
          Marker(
            point: LatLng(stop.lat!, stop.lng!),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => openStopDetail(context, stop),
              child: StopPin(stop: stop),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureLayers(Theme.of(context).colorScheme.primary);
    if (_located.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Sin ubicaciones',
        message: 'Las paradas no tienen coordenadas. Usa la lista.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final options = _options ??= _initialOptions(constraints.biggest);
        return _buildMap(options);
      },
    );
  }

  MapOptions _initialOptions(Size size) {
    final initial = fittedInitialCamera(
      points: _fitPoints,
      size: size,
      padding: _fitPadding,
      maxZoom: 17,
    );
    return MapOptions(
      initialCenter: initial.center,
      initialZoom: initial.zoom,
      minZoom: kDriverMapMinZoom,
      maxZoom: kMapMaxZoom,
      interactionOptions: kDriverMapInteraction,
    );
  }

  Widget _buildMap(MapOptions options) {
    return Stack(
      children: [
        // El mapa en su propia capa: los botones de encima no lo repintan.
        RepaintBoundary(
          child: FlutterMap(
            mapController: _controller,
            options: options,
            children: [const OsmTileLayer(), _lineLayer, _stopsLayer],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapZoomButtons(controller: _controller),
              const SizedBox(height: 10),
              MapRoundButton(
                tooltip: 'Ver toda la ruta',
                icon: Icons.zoom_out_map,
                onPressed: () {
                  if (_fitPoints.length < 2) return;
                  _controller.fitCamera(
                    CameraFit.coordinates(
                      coordinates: _fitPoints,
                      padding: _fitPadding,
                      maxZoom: 17,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
