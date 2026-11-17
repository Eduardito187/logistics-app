import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/power/motion_budget.dart';
import '../radar_pulse.dart';
import 'truck_marker.dart';

/// Capa del camión que se DESLIZA suave entre un fix del GPS y el siguiente, al
/// estilo de las apps de taxi (Uber/inDrive), para que no se note el "salto"
/// cada vez que llega una posición nueva.
///
/// El problema: el rastreo entrega una posición cada ~2 s (perfil en marcha). Si
/// el marcador se dibuja en el LatLng CRUDO de cada fix, el camión se
/// TELETRANSPORTA cada 2 s — justo el salto que se ve cortado. Acá se interpola
/// la posición mostrada desde la anterior hasta la nueva a lo largo del tiempo
/// REAL que tardó en llegar el fix (así el camión avanza a velocidad pareja y
/// llega al punto nuevo justo cuando aparece el siguiente). El rumbo ya lo anima
/// [TruckMarker] por su cuenta; esto resuelve la POSICIÓN.
///
/// Rendimiento (teléfonos de gama baja, en campo): el deslizamiento reconstruye
/// solo esta capa (dos marcadores) por frame mientras dura, y el mapa va en un
/// `RepaintBoundary` aparte. Con reduce-motion del sistema o en ahorro de
/// energía / batería baja ([MotionBudget]) NO se interpola: salta directo al
/// punto nuevo (igual que antes), que es lo barato. El radar late una vez por
/// fix (no por frame), porque su `trigger` es el objetivo crudo, no la posición
/// interpolada.
class AnimatedDriverMarkers extends StatefulWidget {
  const AnimatedDriverMarkers({
    super.key,
    required this.target,
    required this.heading,
    required this.reduceMotion,
    this.onGlide,
    this.size = 52,
    this.radarSize = 120,
  });

  /// Posición CRUDA del último fix del GPS (destino del deslizamiento).
  final LatLng target;

  /// Rumbo del camión en grados (0 = norte); lo anima [TruckMarker].
  final double? heading;

  /// Reduce-motion del sistema (`MediaQuery.disableAnimationsOf`): si está, no
  /// se interpola (salta directo).
  final bool reduceMotion;

  /// Se llama con la posición INTERPOLADA en cada frame del deslizamiento (y una
  /// vez al saltar): la usa el modo "seguir" para que la cámara acompañe al
  /// camión igual de suave, en vez de pegar el tirón del fix crudo.
  final ValueChanged<LatLng>? onGlide;

  /// Lado del marcador del camión (dp).
  final double size;

  /// Lado del área del radar (dp).
  final double radarSize;

  /// Reloj inyectable (tests): la separación entre fixes fija la duración del
  /// deslizamiento.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  @override
  State<AnimatedDriverMarkers> createState() => _AnimatedDriverMarkersState();
}

class _AnimatedDriverMarkersState extends State<AnimatedDriverMarkers>
    with SingleTickerProviderStateMixin {
  /// Deslizamiento de la posición: corre una vez por fix nuevo, del punto
  /// anterior al nuevo. Su duración se fija en cada retarget (ver
  /// [didUpdateWidget]); por eso no se pasa `duration` acá.
  late final AnimationController _glide = AnimationController(vsync: this);

  /// Extremos del deslizamiento en curso y la posición mostrada ahora.
  LatLng _from = const LatLng(0, 0);
  LatLng _to = const LatLng(0, 0);
  LatLng _displayed = const LatLng(0, 0);

  /// Momento del último fix recibido: la separación con el siguiente fija la
  /// duración del deslizamiento (así avanza a la velocidad real, sin overshoot).
  DateTime? _lastTargetAt;

  /// Piso y techo de la duración del deslizamiento: nunca instantáneo (se vería
  /// salto) ni larguísimo (un fix que tardó por mala señal no debe dejar al
  /// camión arrastrándose un minuto).
  static const Duration _minGlide = Duration(milliseconds: 500);
  static const Duration _maxGlide = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _displayed = widget.target;
    _from = widget.target;
    _to = widget.target;
    _glide.addListener(_tick);
  }

  void _tick() {
    final t = _glide.value;
    // Lineal a propósito: un camión en marcha avanza a velocidad pareja; una
    // curva easeOut lo haría frenar antes de cada punto y se vería "a tirones".
    setState(() {
      _displayed = LatLng(
        _from.latitude + (_to.latitude - _from.latitude) * t,
        _from.longitude + (_to.longitude - _from.longitude) * t,
      );
    });
    widget.onGlide?.call(_displayed);
  }

  @override
  void didUpdateWidget(AnimatedDriverMarkers old) {
    super.didUpdateWidget(old);
    if (old.target == widget.target) return;
    final now = AnimatedDriverMarkers.clock();
    final previousAt = _lastTargetAt;
    _lastTargetAt = now;

    // Sin animación (reduce-motion o ahorro de energía) o primer fix real:
    // salta directo. Interpolar desde (0,0) o sin señal de tiempo no aporta.
    final snap =
        widget.reduceMotion ||
        !MotionBudget.decorativeAllowed ||
        previousAt == null;
    if (snap) {
      _glide.stop();
      setState(() => _displayed = widget.target);
      _from = widget.target;
      _to = widget.target;
      widget.onGlide?.call(_displayed);
      return;
    }

    // Duración = tiempo que tardó en llegar este fix, acotado: el camión llega
    // al punto nuevo justo cuando aparecería el siguiente → movimiento continuo.
    var dur = now.difference(previousAt);
    if (dur < _minGlide) dur = _minGlide;
    if (dur > _maxGlide) dur = _maxGlide;

    // Arranca desde donde se está mostrando (no desde el fix anterior): si un
    // fix llega a mitad del deslizamiento, re-apunta suave sin tirón.
    _from = _displayed;
    _to = widget.target;
    _glide
      ..duration = dur
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _glide.removeListener(_tick);
    _glide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Un solo MarkerLayer con el radar (debajo) y el camión (encima), ambos en
    // la posición interpolada. El radar se dispara con el objetivo CRUDO para
    // latir una vez por fix, no por frame.
    return MarkerLayer(
      markers: [
        Marker(
          point: _displayed,
          width: widget.radarSize,
          height: widget.radarSize,
          child: RadarPulse(size: widget.radarSize, trigger: widget.target),
        ),
        Marker(
          point: _displayed,
          width: widget.size,
          height: widget.size,
          child: TruckMarker(headingDegrees: widget.heading, size: widget.size),
        ),
      ],
    );
  }
}
