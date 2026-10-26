import 'dart:async';
import 'dart:math' as math;

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
import '../map_zoom_buttons.dart';
import '../route_points.dart';
import 'map_round_button.dart';

export '../route_points.dart'
    show routeGeometryPoints, routePrefetchPoints, simplifiedRoutePoints;

/// Posición del camión: la del rastreo en vivo si está activo; si no, una
/// lectura puntual del GPS al abrir la pantalla.
final deliveryDriverFixProvider = FutureProvider.autoDispose<GpsFix?>((ref) {
  final live = ref.watch(truckTrackingProvider.select((s) => s.lastFix));
  if (live != null) return live;
  return ref.read(locationServiceProvider).current();
});

/// Distancia máxima (km) del camión a la ruta para tomar su GPS como válido.
/// Más lejos es una lectura imposible para un reparto urbano (GPS de prueba
/// del emulador, fix viejo de otra ciudad): se ignora en vez de alejar el mapa
/// a nivel continente y mostrar "faltan 12000 km".
const double kMaxPlausibleDriverKm = 100;

/// Posición del camión si es creíble para [route] (dentro del rectángulo de
/// la ruta —paradas y trazo— ampliado [kMaxPlausibleDriverKm]); si no, `null`.
///
/// Barato a propósito (se evalúa con cada fix del GPS en el mapa y en la
/// tarjeta): el rectángulo se calcula una vez por ruta y el chequeo es O(1).
/// Además el último resultado se reusa: con la misma ruta y el mismo fix no se
/// recalcula (mapa, seguimiento y tarjeta piden lo mismo en el mismo frame).
GpsFix? plausibleDriverFix(DriverRoute route, GpsFix? fix) {
  if (fix == null) return null;
  final last = _lastPlausible;
  if (last != null &&
      identical(last.route, route) &&
      identical(last.fix, fix)) {
    return last.result;
  }
  final bounds = _plausibleBounds(route);
  final result = bounds == null || bounds.contains(fix.lat, fix.lng)
      ? fix
      : null;
  _lastPlausible = (route: route, fix: fix, result: result);
  return result;
}

/// Último cálculo de [plausibleDriverFix] (una entrada: el fix más reciente).
({DriverRoute route, GpsFix fix, GpsFix? result})? _lastPlausible;

/// Rectángulo de la ruta ampliado, memoizado por instancia de la ruta (el
/// `Expando` no la retiene). `null` cuando la ruta no tiene puntos.
final Expando<_LatLngBox> _plausibleBoxes = Expando('plausibleBounds');

/// Marcador de "ruta sin puntos" en el `Expando` (no admite `null`).
const _LatLngBox _noBox = _LatLngBox(0, 0, 0, 0);

_LatLngBox? _plausibleBounds(DriverRoute route) {
  final cached = _plausibleBoxes[route];
  if (cached != null) return identical(cached, _noBox) ? null : cached;
  final points = routePrefetchPoints(route);
  if (points.isEmpty) {
    _plausibleBoxes[route] = _noBox;
    return null;
  }
  var south = points.first.latitude;
  var north = south;
  var west = points.first.longitude;
  var east = west;
  for (final p in points) {
    if (p.latitude < south) south = p.latitude;
    if (p.latitude > north) north = p.latitude;
    if (p.longitude < west) west = p.longitude;
    if (p.longitude > east) east = p.longitude;
  }
  // 1° de latitud ≈ 111,32 km; la longitud se achica con el coseno de la
  // latitud (se toma la más alejada del ecuador: margen nunca menor al pedido).
  const kmPerDegree = 111.32;
  final latMargin = kMaxPlausibleDriverKm / kmPerDegree;
  final maxAbsLat = math.min(
    89.0,
    math.max(south.abs(), north.abs()) + latMargin,
  );
  final lngMargin =
      kMaxPlausibleDriverKm /
      (kmPerDegree * math.max(math.cos(maxAbsLat * math.pi / 180), 0.01));
  final box = _LatLngBox(
    south - latMargin,
    north + latMargin,
    west - lngMargin,
    east + lngMargin,
  );
  _plausibleBoxes[route] = box;
  return box;
}

class _LatLngBox {
  const _LatLngBox(this.south, this.north, this.west, this.east);

  final double south;
  final double north;
  final double west;
  final double east;

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;
}

/// Distancia/tiempo restantes del camión a [stop] y si está fuera de ruta.
/// `null` sin posición creíble del camión o sin coordenadas de la parada.
RemainingEstimate? remainingToStop(
  DriverRoute route,
  DriverRouteStop stop,
  GpsFix? rawFix,
) {
  final fix = plausibleDriverFix(route, rawFix);
  if (fix == null || stop.lat == null || stop.lng == null) return null;
  final geometry = route.routeGeometry;
  return estimateRemaining(
    from: LatLng(fix.lat, fix.lng),
    to: LatLng(stop.lat!, stop.lng!),
    geometry: simplifiedRoutePoints(geometry),
    geometryMeters: geometry?.distanceMeters,
    geometrySeconds: geometry?.durationSeconds,
  );
}

/// Precarga de tiles del mapa (inyectable para tests: sin red ni disco).
/// [routeKey]: clave estable de la ruta (su id) para que el core la precargue
/// una sola vez aunque el trazo cambie apenas entre recargas.
typedef RouteTilePrefetcher =
    Future<void> Function(List<LatLng> points, {String? routeKey});

/// Al abrir la entrega en curso se precargan los tiles de la ruta (paradas y
/// trazo) para que el mapa se vea aunque después se pierda la señal.
final routeTilePrefetcherProvider = Provider<RouteTilePrefetcher>(
  (ref) =>
      (points, {routeKey}) => prefetchRouteTiles(points, routeKey: routeKey),
);

/// Mapa de la entrega en curso: destino, camión y el trazo, más las paradas
/// siguientes en gris. El trazo es la ruta por calles del plan
/// (`DriverRoute.routeGeometry`, simplificada una vez); si el backend no la
/// tiene, una línea directa camión → destino.
///
/// Modo "seguir": centra el mapa en el camión cada vez que se mueve; se activa
/// con su botón y se apaga solo al arrastrar el mapa con el dedo.
///
/// Rendimiento (GPS cada pocos segundos en teléfonos de 1 GB): las capas que
/// no dependen del camión (trazo, destino y paradas) se arman una sola vez por
/// ruta/parada y se reusan como la MISMA instancia de widget, así Flutter no
/// las reconstruye y flutter_map no vuelve a proyectar los puntos del trazo
/// en cada fix. Solo la capa del camión cambia con el GPS.
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

  /// Opciones del mapa: se arman con el primer encuadre y se reusan (el
  /// centro/zoom inicial solo cuentan al crear el mapa).
  MapOptions? _options;

  // Capas estáticas memoizadas y la clave (ruta, parada, color) con que se
  // armaron.
  DriverRoute? _layersRoute;
  DriverRouteStop? _layersStop;
  Color? _layersColor;
  List<LatLng> _upcoming = const [];
  Widget? _streetsLayer;
  Widget _stopsLayer = const SizedBox.shrink();

  /// Precarga de tiles diferida: arranca después de la transición de entrada
  /// para no competir con el primer dibujo del mapa (los tiles visibles).
  Timer? _prefetchTimer;

  /// Demora de la precarga tras el primer frame (≈ fin de la transición).
  static const Duration _prefetchDelay = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchTimer = Timer(_prefetchDelay, _prefetchTiles);
    });
  }

  void _prefetchTiles() {
    if (!mounted) return;
    final points = routePrefetchPoints(widget.route);
    if (points.isEmpty) return;
    // Best-effort y sin bloquear la pantalla: un fallo no se muestra. El core
    // la hace una sola vez por ruta (reabrir la pantalla no repite trabajo).
    unawaited(
      ref
          .read(routeTilePrefetcherProvider)(points, routeKey: widget.route.id)
          .catchError((Object _) {}),
    );
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
    _prefetchTimer?.cancel();
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

  /// Arma (una vez por ruta/parada/color) el trazo, las paradas siguientes y
  /// sus capas. Con la misma ruta, parada y color no hace nada.
  void _ensureStaticLayers(Color lineColor) {
    if (identical(_layersRoute, widget.route) &&
        identical(_layersStop, widget.stop) &&
        _layersColor == lineColor) {
      return;
    }
    _layersRoute = widget.route;
    _layersStop = widget.stop;
    _layersColor = lineColor;
    final streets = simplifiedRoutePoints(widget.route.routeGeometry);
    _upcoming = [
      for (final s in widget.route.stops)
        if (s.id != widget.stop.id &&
            s.status == DriverRouteStopStatus.pending &&
            s.lat != null &&
            s.lng != null)
          LatLng(s.lat!, s.lng!),
    ];
    _streetsLayer = streets.length >= 2
        ? PolylineLayer(
            polylines: [
              Polyline(points: streets, strokeWidth: 5, color: lineColor),
            ],
          )
        : null;
    final destination = _destination;
    _stopsLayer = MarkerLayer(
      markers: [
        for (final p in _upcoming)
          Marker(point: p, width: 18, height: 18, child: const _UpcomingDot()),
        if (destination != null)
          Marker(
            point: destination,
            width: 56,
            height: 56,
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.location_on,
              size: 56,
              color: lineColor,
              semanticLabel: 'Destino',
            ),
          ),
      ],
    );
  }

  /// Encuadre inicial: camión + destino si hay GPS creíble; si no, la ruta
  /// del día completa (trazo y paradas) para que siempre se vea el recorrido.
  ({LatLng center, double zoom}) _initialCamera(
    Size size,
    LatLng anchor,
    LatLng? destination,
    LatLng? driver,
  ) {
    final both = destination != null && driver != null;
    final points = both
        ? [destination, driver]
        : routePrefetchPoints(widget.route);
    if (points.length < 2) return (center: anchor, zoom: 15);
    return fittedInitialCamera(
      points: points,
      size: size,
      padding: _fitPadding,
      maxZoom: both ? 18 : 17,
    );
  }

  /// Arma las opciones con el primer encuadre y las guarda: flutter_map solo
  /// usa el centro/zoom iniciales al crear el mapa, así que recalcular el
  /// encuadre en cada fix del GPS era trabajo tirado.
  MapOptions _optionsFor(({LatLng center, double zoom}) initial) =>
      _options ??= MapOptions(
        initialCenter: initial.center,
        initialZoom: initial.zoom,
        minZoom: kDriverMapMinZoom,
        maxZoom: kMapMaxZoom,
        interactionOptions: kDriverMapInteraction,
        // Arrastrar el mapa con el dedo apaga el modo seguir.
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _follow) setState(() => _follow = false);
        },
      );

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
    // Al moverse el camión, si está en modo seguir, el mapa lo acompaña. El
    // fix creíble se calcula UNA vez por fix (memoizado) y lo reusan el
    // seguimiento, el mapa y la tarjeta de estado.
    ref.listen(deliveryDriverFixProvider, (_, next) {
      if (!_follow) return;
      final f = plausibleDriverFix(widget.route, next.value);
      if (f != null) _followTo(LatLng(f.lat, f.lng));
    });
    final fix = plausibleDriverFix(
      widget.route,
      ref.watch(deliveryDriverFixProvider).value,
    );
    final driver = fix == null ? null : LatLng(fix.lat, fix.lng);
    final scheme = Theme.of(context).colorScheme;
    _ensureStaticLayers(scheme.onSurface);

    return LayoutBuilder(
      builder: (context, constraints) {
        final destination = _destination;
        final anchor =
            destination ??
            driver ??
            (_upcoming.isNotEmpty ? _upcoming.first : null) ??
            const LatLng(-17.7833, -63.1821); // Santa Cruz por defecto.
        final options =
            _options ??
            _optionsFor(
              _initialCamera(constraints.biggest, anchor, destination, driver),
            );
        return _buildMap(context, options, driver: driver, scheme: scheme);
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    MapOptions options, {
    required LatLng? driver,
    required ColorScheme scheme,
  }) {
    final destination = _destination;
    return Stack(
      children: [
        // El mapa en su propia capa: la tarjeta, la hoja y los botones de
        // encima no lo repintan (ni él a ellos con cada fix).
        RepaintBoundary(
          child: FlutterMap(
            mapController: _controller,
            options: options,
            children: [
              const OsmTileLayer(),
              if (_streetsLayer != null)
                _streetsLayer!
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
              _stopsLayer,
              // Única capa que cambia con cada fix del GPS.
              if (driver != null)
                MarkerLayer(
                  markers: [
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
        ),
        Positioned(
          right: 12,
          // Encima de la hoja colapsada (≈32% del alto).
          bottom: MediaQuery.sizeOf(context).height * 0.32 + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapZoomButtons(controller: _controller),
              const SizedBox(height: 10),
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
