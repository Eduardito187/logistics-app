import 'dart:math' as math;

import 'gps_fix.dart';
import 'tracking_profile.dart';

/// Decide si el camión está en marcha o detenido a partir de las lecturas del
/// GPS. Pura (sin timers ni plataforma): el reloj lo pasa quien la usa.
///
/// - Se fija un "ancla" y su hora. Si una lectura cae a más de
///   [movingRadiusMeters] del ancla (o de la precisión de la lectura, si es
///   peor), el camión se movió: el ancla pasa a esa lectura y el modo vuelve a
///   [TruckMotion.moving].
/// - Si pasan [stillAfter] sin salir del radio, el modo pasa a
///   [TruckMotion.stationary]. Así el jitter del GPS estando parado (5–30 m) no
///   cuenta como movimiento.
class MotionDetector {
  MotionDetector({
    this.movingRadiusMeters = 40,
    this.maxJitterMeters = 150,
    this.stillAfter = const Duration(minutes: 3),
  });

  /// Radio dentro del cual el camión se considera quieto.
  final double movingRadiusMeters;

  /// Tope de la precisión que se usa para agrandar el radio (lecturas muy
  /// malas no deben impedir detectar el movimiento).
  final double maxJitterMeters;

  /// Tiempo sin salir del radio para considerarlo detenido.
  final Duration stillAfter;

  GpsFix? _anchor;
  DateTime? _anchorAt;
  TruckMotion _motion = TruckMotion.moving;

  /// Modo actual (arranca en marcha: al empezar la ruta se asume movimiento).
  TruckMotion get motion => _motion;

  /// Registra una lectura. Devuelve `true` si el modo cambió.
  bool onFix(GpsFix fix, DateTime now) {
    final anchor = _anchor;
    if (anchor == null) {
      _anchor = fix;
      _anchorAt = now;
      return false;
    }
    final jitter = math.min(fix.accuracy ?? 0, maxJitterMeters);
    final radius = math.max(movingRadiusMeters, jitter);
    if (distanceMeters(anchor, fix) > radius) {
      _anchor = fix;
      _anchorAt = now;
      if (_motion != TruckMotion.moving) {
        _motion = TruckMotion.moving;
        return true;
      }
      return false;
    }
    return evaluate(now);
  }

  /// Revisa (sin lectura nueva) si ya corresponde pasar a detenido. Devuelve
  /// `true` si el modo cambió.
  bool evaluate(DateTime now) {
    final at = _anchorAt;
    if (_motion == TruckMotion.moving &&
        at != null &&
        now.difference(at) >= stillAfter) {
      _motion = TruckMotion.stationary;
      return true;
    }
    return false;
  }

  /// Cuánto falta para pasar a detenido si nada se mueve (`null` si ya está
  /// detenido o todavía no hay lecturas).
  Duration? timeUntilStill(DateTime now) {
    final at = _anchorAt;
    if (_motion != TruckMotion.moving || at == null) return null;
    final left = stillAfter - now.difference(at);
    return left.isNegative ? Duration.zero : left;
  }

  /// Olvida el ancla y vuelve a "en marcha" (al reiniciar el rastreo).
  void reset() {
    _anchor = null;
    _anchorAt = null;
    _motion = TruckMotion.moving;
  }

  /// Distancia (m) entre dos lecturas por la fórmula del semiverseno.
  static double distanceMeters(GpsFix a, GpsFix b) {
    const earthRadius = 6371000.0;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
  }
}
