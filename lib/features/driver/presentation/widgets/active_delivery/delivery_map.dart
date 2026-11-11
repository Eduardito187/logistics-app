import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/icons/icons.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/location/truck_tracking_service.dart';
import '../../../../../core/map/dark_map_canvas.dart';
import '../../../../../core/map/osm_tile_layer.dart';
import '../../../../../core/map/tile_prefetch.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/route_navigation.dart';
import '../map_motion.dart';
import '../map_zoom_buttons.dart';
import '../radar_pulse.dart';
import '../route_points.dart';
import '../stop_pin.dart';
import 'truck_marker.dart';

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

class _DeliveryMapState extends ConsumerState<DeliveryMap>
    with SingleTickerProviderStateMixin {
  final MapController _controller = MapController();
  // Se asigna en initState (no `late` perezoso): un acceso perezoso desde
  // dispose crearía el AnimationController con el widget ya desmontado.
  late final AnimatedMapMover _mover;

  /// Modo "seguir al camión".
  bool _follow = false;

  /// Última posición usada para calcular el rumbo del camión y el rumbo actual
  /// (grados, 0 = norte). Se actualiza solo cuando el camión se movió lo
  /// suficiente (umbral), así el camión no "tiembla" girando con el jitter del
  /// GPS estando parado.
  LatLng? _headingFrom;
  double? _heading;

  /// Metros que debe moverse el camión para recalcular su rumbo.
  static const double _headingMinMeters = 4;

  /// Zoom al seguir: suficiente para ver la cuadra siguiente.
  static const double _followZoom = 17;

  // --- Auto-enfoque al quedar todo quieto -----------------------------------
  // Cuando NI el usuario mueve el mapa NI el camión se mueve por unos segundos,
  // el mapa se acerca suavemente a la ubicación del camión. Nunca se mueve el
  // mapa mientras el dedo lo está arrastrando o el camión va en marcha (sería
  // molesto). Es un enfoque automático distinto del modo "seguir" manual.

  /// Momento del último gesto del usuario sobre el mapa (arrastre/pellizco).
  DateTime _lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Posición donde el camión quedó quieto y desde cuándo. Si se mueve más de
  /// [_stationaryMeters] se reinicia (el camión está en marcha).
  LatLng? _truckStillAt;
  DateTime? _truckStillSince;

  /// Ya se hizo el auto-enfoque para la quietud actual: no se repite hasta que
  /// el camión se mueva o el usuario toque el mapa otra vez.
  bool _autoFocused = false;

  /// Chequea cada segundo si corresponde auto-enfocar.
  Timer? _idleTimer;

  /// El camión se considera "en marcha" si se movió más que esto entre fixes
  /// (tolera el jitter del GPS estando parado).
  static const double _stationaryMeters = 12;

  /// Segundos que deben estar quietos TANTO el mapa como el camión.
  static const Duration _idleWindow = Duration(seconds: 6);

  /// Zoom objetivo del auto-enfoque (nunca aleja: respeta un zoom mayor).
  static const double _autoFocusZoom = 16.5;

  /// Opciones del mapa: se arman con el primer encuadre y se reusan (el
  /// centro/zoom inicial solo cuentan al crear el mapa).
  MapOptions? _options;

  // Capas estáticas memoizadas y la clave (ruta, parada, color) con que se
  // armaron.
  DriverRoute? _layersRoute;
  DriverRouteStop? _layersStop;
  Color? _layersColor;
  List<LatLng> _upcoming = const [];
  List<DriverRouteStop> _upcomingStops = const [];
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
    _mover = AnimatedMapMover(vsync: this, controller: _controller);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchTimer = Timer(_prefetchDelay, _prefetchTiles);
    });
    // Chequeo liviano (1 s) de "todo quieto" para el auto-enfoque. No toca el
    // GPS ni la red: solo compara marcas de tiempo y mueve la cámara si procede.
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _maybeAutoFocus();
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
    _idleTimer?.cancel();
    _mover.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Registra la posición del camión para saber si está quieto. Si se movió más
  /// de [_stationaryMeters] desde la última posición de reposo, el camión está
  /// en marcha: se reinicia el reloj de quietud y se habilita un nuevo
  /// auto-enfoque para cuando vuelva a detenerse.
  void _trackStillness(LatLng driver) {
    final anchor = _truckStillAt;
    if (anchor == null ||
        const Distance()(anchor, driver) > _stationaryMeters) {
      _truckStillAt = driver;
      _truckStillSince = DateTime.now();
      _autoFocused = false;
    }
  }

  /// Acerca el mapa a la ubicación del camión SOLO si lleva quieto [_idleWindow]
  /// y el usuario no tocó el mapa en ese mismo lapso (y no hay otra animación en
  /// curso ni modo seguir activo). Se hace una sola vez por cada quietud.
  void _maybeAutoFocus() {
    if (!mounted) return;
    final still = _truckStillAt;
    if (!shouldAutoFocus(
      now: DateTime.now(),
      truckStillSince: _truckStillSince,
      lastGestureAt: _lastGestureAt,
      follow: _follow,
      autoFocused: _autoFocused,
      animating: _mover.isAnimating,
      window: _idleWindow,
    )) {
      return;
    }
    if (still == null) return;
    _autoFocused = true;
    final zoom = math.max(_controller.camera.zoom, _autoFocusZoom);
    _mover.animateTo(
      still,
      zoom,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
  }

  void _followTo(LatLng driver) {
    final zoom = _controller.camera.zoom;
    _controller.move(driver, zoom < _followZoom ? _followZoom : zoom);
  }

  void _toggleFollow(LatLng? driver) {
    setState(() => _follow = !_follow);
    if (_follow && driver != null) _followTo(driver);
  }

  void _zoomBy(double delta) {
    // Transición suave: el move directo hacía saltar el mapa y cortaba tiles.
    // El mover acumula los toques rápidos sobre el zoom pendiente.
    _mover.zoomBy(
      delta,
      min: kDriverMapMinZoom,
      max: kMapMaxZoom,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
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
    _upcomingStops = [
      for (final s in widget.route.stops)
        if (s.id != widget.stop.id &&
            s.status == DriverRouteStopStatus.pending &&
            s.lat != null &&
            s.lng != null)
          s,
    ];
    _upcoming = [for (final s in _upcomingStops) LatLng(s.lat!, s.lng!)];
    // Trazo con glow: línea ancha translúcida de marca por debajo y una fina
    // sólida de marca encima (StrokeCap.round por defecto en flutter_map v7).
    _streetsLayer = streets.length >= 2
        ? PolylineLayer(
            polylines: [
              Polyline(
                points: streets,
                strokeWidth: 12,
                color: lineColor.withValues(alpha: 0.28),
              ),
              Polyline(points: streets, strokeWidth: 4, color: lineColor),
            ],
          )
        : null;
    final destination = _destination;
    const upcomingSize = 30.0;
    const destSize = 52.0;
    _stopsLayer = MarkerLayer(
      markers: [
        // Paradas siguientes: pines chicos numerados, coloreados por estado.
        for (final s in _upcomingStops)
          Marker(
            point: LatLng(s.lat!, s.lng!),
            width: upcomingSize,
            height: StopPin.heightFor(upcomingSize),
            alignment: Alignment.topCenter,
            child: StopPin(stop: s, size: upcomingSize),
          ),
        // Destino: pin teardrop destacado de marca con glow y el pin de lugar.
        if (destination != null)
          Marker(
            point: destination,
            width: destSize,
            height: TeardropPin.heightFor(destSize),
            alignment: Alignment.topCenter,
            child: const TeardropPin(
              color: AppColors.brand,
              size: destSize,
              glow: true,
              child: AnimatedAppIcon(
                AppIcon.place,
                size: 30,
                color: Colors.white,
                semanticLabel: 'Destino',
              ),
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
  MapOptions _optionsFor(
    ({LatLng center, double zoom}) initial,
  ) => _options ??= MapOptions(
    initialCenter: initial.center,
    initialZoom: initial.zoom,
    minZoom: kDriverMapMinZoom,
    maxZoom: kMapMaxZoom,
    interactionOptions: kDriverMapInteraction,
    // Un gesto del usuario (arrastrar/pellizcar) apaga el modo seguir,
    // marca el momento del toque (para no auto-enfocar encima) y habilita un
    // nuevo auto-enfoque cuando todo vuelva a quedar quieto.
    onPositionChanged: (camera, hasGesture) {
      if (!hasGesture) return;
      _lastGestureAt = DateTime.now();
      _autoFocused = false;
      if (_follow) setState(() => _follow = false);
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
      final f = plausibleDriverFix(widget.route, next.value);
      if (f == null) return;
      final pos = LatLng(f.lat, f.lng);
      // Siempre se mide la quietud del camión (para el auto-enfoque); el modo
      // seguir, si está activo, acompaña además cada movimiento.
      _trackStillness(pos);
      if (_follow) _followTo(pos);
    });
    final fix = plausibleDriverFix(
      widget.route,
      ref.watch(deliveryDriverFixProvider).value,
    );
    final driver = fix == null ? null : LatLng(fix.lat, fix.lng);
    // Rumbo del camión: ángulo del último tramo recorrido (si se movió lo
    // suficiente), para orientarlo en el mapa como Uber/inDrive.
    if (driver != null) {
      final from = _headingFrom;
      if (from == null) {
        _headingFrom = driver;
      } else if (const Distance()(from, driver) >= _headingMinMeters) {
        _heading = _bearingDegrees(from, driver);
        _headingFrom = driver;
      }
    }
    // El trazo y la línea directa van en rojo de marca para el look con glow
    // sobre el mapa oscuro.
    _ensureStaticLayers(AppColors.brand);

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
        return _buildMap(context, options, driver: driver);
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    MapOptions options, {
    required LatLng? driver,
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
              const DarkMapTiles(),
              const DarkMapScrim(),
              if (_streetsLayer != null)
                _streetsLayer!
              else if (destination != null && driver != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [driver, destination],
                      strokeWidth: 12,
                      color: AppColors.brand.withValues(alpha: 0.28),
                    ),
                    Polyline(
                      points: [driver, destination],
                      strokeWidth: 4,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              _stopsLayer,
              // Capas que cambian con cada fix del GPS: el radar debajo del
              // camión (solo con fix en vivo) y el marcador del camión encima.
              if (driver != null) ...[
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driver,
                      width: 120,
                      height: 120,
                      // trigger: cada fix del GPS dispara un ping finito.
                      child: RadarPulse(size: 120, trigger: driver),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driver,
                      width: 52,
                      height: 52,
                      // Camión visto desde arriba que apunta al rumbo (Uber/
                      // inDrive): rota suave al doblar o retroceder.
                      child: TruckMarker(headingDegrees: _heading, size: 52),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: 14,
          // Al PIE del mapa (ya no hay hoja persistente que los tapara: antes
          // iban a ≈32% del alto y la hoja los cubría). Agrupados en una sola
          // tarjeta compacta, justo encima de la barra de acciones.
          bottom: 16,
          child: _MapControls(
            children: [
              _MapControlButton(
                tooltip: 'Acercar',
                icon: AppIcon.add,
                onPressed: () => _zoomBy(1),
              ),
              const _MapControlDivider(),
              _MapControlButton(
                tooltip: 'Alejar',
                icon: AppIcon.remove,
                onPressed: () => _zoomBy(-1),
              ),
              if (driver != null) ...[
                const _MapControlDivider(),
                _MapControlButton(
                  tooltip: _follow ? 'Dejar de seguir' : 'Seguir camión',
                  icon: AppIcon.navigation,
                  selected: _follow,
                  onPressed: () => _toggleFollow(driver),
                ),
              ],
              const _MapControlDivider(),
              _MapControlButton(
                tooltip: 'Centrar',
                icon: AppIcon.gps,
                onPressed: () => _recenter(driver),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ¿Corresponde auto-enfocar el mapa en el camión quieto? `true` solo si nada se
/// mueve: no está activo el modo seguir, no se auto-enfocó ya para esta
/// quietud, no hay otra animación de cámara, el camión lleva quieto al menos
/// [window] y el usuario no tocó el mapa en ese mismo lapso. Pura (sin estado ni
/// tiempo real) para poder testear la regla con fechas controladas.
bool shouldAutoFocus({
  required DateTime now,
  required DateTime? truckStillSince,
  required DateTime lastGestureAt,
  required bool follow,
  required bool autoFocused,
  required bool animating,
  required Duration window,
}) {
  if (follow || autoFocused || animating) return false;
  if (truckStillSince == null) return false;
  if (now.difference(truckStillSince) < window) return false;
  if (now.difference(lastGestureAt) < window) return false;
  return true;
}

/// Rumbo (grados, 0 = norte, 90 = este) del tramo [a]→[b], para orientar el
/// camión en el mapa.
double _bearingDegrees(LatLng a, LatLng b) {
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Tarjeta flotante que agrupa los controles del mapa (acercar, alejar, seguir,
/// centrar) en un solo bloque compacto. Ocupa menos alto que botones sueltos,
/// así no se encima con el bloque de estado/"Ayuda" en pantallas cortas, y se
/// lee como un control único (mejor UX).
class _MapControls extends StatelessWidget {
  const _MapControls({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Línea divisoria tenue entre controles de la tarjeta.
class _MapControlDivider extends StatelessWidget {
  const _MapControlDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: 10,
    endIndent: 10,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

/// Un control del mapa dentro de la tarjeta: botón táctil de 48 con el ícono
/// animado DisTrack; relleno de marca cuando está [selected] (modo "seguir").
class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final AppIcon icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      // Más chicos aún (antes 42/20): la columna ocupa menos alto y no la tapa
      // la tarjeta de estado cuando el mapa queda corto.
      iconSize: 18,
      padding: EdgeInsets.zero,
      color: selected ? scheme.primary : null,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      icon: AnimatedAppIcon(
        icon,
        state: selected ? AppIconState.active : AppIconState.idle,
      ),
    );
  }
}
