import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Estimación de lo que falta para llegar a la parada en curso.
///
/// No hay maniobras del backend (giro a giro): esto solo da distancia y tiempo
/// restantes aproximados y si el camión se salió del trazo. La navegación paso
/// a paso se delega a la app de mapas ("Navegar").
class RemainingEstimate {
  const RemainingEstimate({
    required this.meters,
    required this.duration,
    required this.alongRoute,
    required this.offRoute,
  });

  /// Distancia restante estimada, en metros.
  final double meters;

  /// Tiempo restante estimado.
  final Duration duration;

  /// `true` si se midió sobre el trazo por calles; `false` si es línea recta
  /// corregida por [kStraightLineDetourFactor].
  final bool alongRoute;

  /// `true` si el camión está a más de [kOffRouteThresholdMeters] del trazo.
  final bool offRoute;
}

/// Distancia (m) al trazo a partir de la cual se avisa "Fuera de ruta".
const double kOffRouteThresholdMeters = 150;

/// Factor de rodeo de la línea recta: por calles se recorre ~40% más.
const double kStraightLineDetourFactor = 1.4;

/// Velocidad urbana promedio (m/s) cuando el trazo no trae duración: 25 km/h.
const double kDefaultUrbanSpeedMps = 25 / 3.6;

const Distance _distance = Distance();

/// Proyección de un punto sobre una polilínea: segmento, fracción dentro del
/// segmento, distancia perpendicular (m) y punto proyectado.
class _Projection {
  const _Projection(this.segment, this.t, this.offset, this.point);

  final int segment;
  final double t;
  final double offset;
  final LatLng point;
}

/// Proyecta [p] sobre el segmento [a]-[b] en un plano local equirectangular
/// (preciso a escala de ciudad). Devuelve la fracción `t` en [0, 1].
double _projectT(LatLng p, LatLng a, LatLng b) {
  final cosLat = math.cos(a.latitudeInRad);
  final ax = a.longitude * cosLat, ay = a.latitude;
  final bx = b.longitude * cosLat, by = b.latitude;
  final px = p.longitude * cosLat, py = p.latitude;
  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return 0;
  return (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
}

LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
  a.latitude + (b.latitude - a.latitude) * t,
  a.longitude + (b.longitude - a.longitude) * t,
);

/// Proyección más cercana de [p] sobre [line] desde el segmento [from].
_Projection? _project(LatLng p, List<LatLng> line, {int from = 0}) {
  _Projection? best;
  for (var i = math.max(0, from); i < line.length - 1; i++) {
    final t = _projectT(p, line[i], line[i + 1]);
    final q = _lerp(line[i], line[i + 1], t);
    final d = _distance(p, q);
    if (best == null || d < best.offset) best = _Projection(i, t, d, q);
  }
  return best;
}

/// Distancia (m) de [p] al trazo [line]. `null` si el trazo tiene < 2 puntos.
double? distanceToPolylineMeters(LatLng p, List<LatLng> line) {
  if (line.length < 2) return null;
  return _project(p, line)?.offset;
}

/// Distancia (m) sobre [line] entre dos proyecciones (de [a] hacia [b]).
double _alongMeters(List<LatLng> line, _Projection a, _Projection b) {
  if (a.segment == b.segment) return _distance(a.point, b.point);
  var total = _distance(a.point, line[a.segment + 1]);
  for (var i = a.segment + 1; i < b.segment; i++) {
    total += _distance(line[i], line[i + 1]);
  }
  return total + _distance(line[b.segment], b.point);
}

/// Estima distancia y tiempo restantes de [from] (camión) a [to] (parada).
///
/// Con trazo por calles ([geometry], ≥ 2 puntos) y el camión dentro de la ruta,
/// se mide sobre el trazo entre la proyección del camión y la de la parada
/// (buscada desde el tramo del camión en adelante). Si no hay trazo, el camión
/// está fuera de ruta o la parada queda "atrás" en el trazo, se usa la línea
/// recta × [kStraightLineDetourFactor]. La velocidad sale del propio trazo
/// (`distance/duration` del backend) o, si no hay, [kDefaultUrbanSpeedMps].
RemainingEstimate estimateRemaining({
  required LatLng from,
  required LatLng to,
  List<LatLng> geometry = const [],
  num? geometryMeters,
  num? geometrySeconds,
}) {
  final speed =
      (geometryMeters != null &&
          geometrySeconds != null &&
          geometryMeters > 0 &&
          geometrySeconds > 0)
      ? geometryMeters / geometrySeconds
      : kDefaultUrbanSpeedMps;

  RemainingEstimate straight({required bool offRoute}) {
    final meters = _distance(from, to) * kStraightLineDetourFactor;
    return RemainingEstimate(
      meters: meters,
      duration: Duration(seconds: (meters / speed).round()),
      alongRoute: false,
      offRoute: offRoute,
    );
  }

  if (geometry.length < 2) return straight(offRoute: false);
  final truck = _project(from, geometry)!;
  final offRoute = truck.offset > kOffRouteThresholdMeters;
  if (offRoute) return straight(offRoute: true);

  final stop = _project(to, geometry, from: truck.segment)!;
  final behind =
      (stop.segment == truck.segment && stop.t < truck.t) ||
      stop.offset > kOffRouteThresholdMeters;
  if (behind) return straight(offRoute: false);

  final meters = _alongMeters(geometry, truck, stop) + stop.offset;
  return RemainingEstimate(
    meters: meters,
    duration: Duration(seconds: (meters / speed).round()),
    alongRoute: true,
    offRoute: false,
  );
}

/// "350 m" o "4,2 km" (separador decimal en español).
String formatDistance(double meters) {
  if (meters < 1000) {
    final rounded = (meters / 10).round() * 10;
    return '$rounded m';
  }
  final km = meters / 1000;
  final text = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} km';
}

/// "< 1 min", "12 min" o "1 h 05 min".
String formatRemainingTime(Duration d) {
  final minutes = (d.inSeconds / 60).round();
  if (minutes < 1) return '< 1 min';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h h ${m.toString().padLeft(2, '0')} min';
}
