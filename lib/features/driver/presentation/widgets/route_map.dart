import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/icons/icons.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../../../core/map/dark_map_canvas.dart';
import '../../../../core/map/osm_tile_layer.dart';
import '../../../../core/theme/app_colors.dart';
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
  const RouteMap({super.key, required this.route, this.fullscreen = false});

  final DriverRoute route;

  /// `true` cuando el mapa se abrió a pantalla completa (desde el botón
  /// "Expandir"): ahí el botón de la esquina cierra en vez de expandir.
  final bool fullscreen;

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

  /// Encaja todo el recorrido (paradas y trazo) en la pantalla.
  void _fitAll() {
    if (_fitPoints.length < 2) return;
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: _fitPoints,
        padding: _fitPadding,
        maxZoom: 17,
      ),
    );
  }

  /// Abre el mapa a PANTALLA COMPLETA (mismo recorrido, sin la hoja de ruta).
  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: RouteMap(route: widget.route, fullscreen: true),
          ),
        ),
      ),
    );
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
    // Trazo con glow: una línea ancha translúcida de marca por debajo y una
    // fina sólida encima, ambas con puntas redondeadas (StrokeCap.round por
    // defecto en flutter_map v7).
    _lineLayer = line.length >= 2
        ? PolylineLayer(
            polylines: [
              Polyline(
                points: line,
                strokeWidth: 12,
                color: lineColor.withValues(alpha: 0.28),
              ),
              Polyline(points: line, strokeWidth: 4, color: lineColor),
            ],
          )
        : const SizedBox.shrink();
    const pinSize = 40.0;
    _stopsLayer = MarkerLayer(
      markers: [
        for (final stop in _located)
          Marker(
            point: LatLng(stop.lat!, stop.lng!),
            width: pinSize,
            height: StopPin.heightFor(pinSize),
            // La punta del pin apunta a la coordenada.
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => openStopDetail(context, stop),
              child: StopPin(stop: stop, size: pinSize),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // El trazo va en rojo de marca para el look con glow sobre el mapa oscuro.
    _ensureLayers(AppColors.brand);
    if (_located.isEmpty) {
      return const EmptyState(
        icon: AppIcon.gpsOff,
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
            children: [
              const DarkMapTiles(),
              const DarkMapScrim(),
              _lineLayer,
              _stopsLayer,
            ],
          ),
        ),
        Positioned(
          right: 12,
          // Separados del borde inferior (gesto del sistema) y de un posible
          // aviso al pie, para que no tapen los botones de zoom.
          bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapZoomButtons(controller: _controller),
              const SizedBox(height: 10),
              MapRoundButton(
                tooltip: 'Ver toda la ruta',
                icon: AppIcon.route,
                onPressed: _fitAll,
              ),
              const SizedBox(height: 10),
              // Esquina: expandir a pantalla completa o, ya en pantalla
              // completa, cerrar y volver.
              widget.fullscreen
                  ? MapRoundButton(
                      tooltip: 'Cerrar',
                      icon: AppIcon.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : MapRoundButton(
                      tooltip: 'Pantalla completa',
                      icon: AppIcon.zoomOut,
                      onPressed: _openFullscreen,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
