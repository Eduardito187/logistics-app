import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Marcador del camión visto desde arriba (top-down), estilo Uber/inDrive:
/// apunta hacia [headingDegrees] (0 = norte/arriba, 90 = este), con un halo
/// claro detrás para leerse sobre cualquier mapa. Rota SUAVE al cambiar de
/// rumbo (animación interna). Pensado para un Marker de flutter_map (size ~52).
///
/// Rendimiento (teléfonos de gama baja, en campo): el dibujo es un
/// `CustomPainter` de pocas formas dentro de un `RepaintBoundary`. Un único
/// `AnimationController` FINITO para el giro (solo corre cuando cambia el
/// rumbo) y repinta por su `Listenable`, sin `setState` por frame. El halo es
/// ESTÁTICO: antes latía en loop infinito repintando dos `MaskFilter.blur` a 60
/// fps (lo más caro de Skia en gama baja) aunque el camión estuviera parado;
/// un glow fijo despega igual al camión del mapa, sin ese gasto continuo. Con
/// reduce-motion (`MediaQuery.disableAnimationsOf`) el giro tampoco anima.
class TruckMarker extends StatefulWidget {
  const TruckMarker({super.key, this.headingDegrees, this.size = 52});

  /// Rumbo de avance en grados (0 = norte/arriba, 90 = este). `null` = sin
  /// rumbo aún → apunta arriba y queda quieto.
  final double? headingDegrees;

  /// Lado del marcador en dp.
  final double size;

  @override
  State<TruckMarker> createState() => _TruckMarkerState();
}

class _TruckMarkerState extends State<TruckMarker>
    with SingleTickerProviderStateMixin {
  /// Giro: corre solo al cambiar de rumbo, del ángulo viejo al nuevo por el
  /// camino más corto. Finito a propósito (no hay loop de rotación). El pintor
  /// se suscribe a este controller (repaint) y lee el ángulo interpolado: no
  /// hay `setState` por frame.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final CurvedAnimation _turnCurve = CurvedAnimation(
    parent: _turn,
    curve: Curves.easeInOut,
  );

  /// Ángulo mostrado cuando NO hay giro en curso (radianes, horario, 0=arriba).
  double _displayed = 0;

  /// Extremos del giro en curso (el pintor interpola entre ellos con la curva).
  double _from = 0;
  double _to = 0;

  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _displayed = _targetRadians();
    _from = _displayed;
    _to = _displayed;
    // Al terminar el giro, fija el ángulo mostrado en el destino.
    _turn.addStatusListener(_onTurnStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduce) return;
    _reduce = reduce;
    if (_reduce) {
      _turn.stop();
      _displayed = _targetRadians();
    }
  }

  @override
  void didUpdateWidget(TruckMarker old) {
    super.didUpdateWidget(old);
    if (old.headingDegrees == widget.headingDegrees) return;
    final target = _targetRadians();
    if (_reduce) {
      // Sin animación: salta directo al nuevo rumbo.
      setState(() => _displayed = target);
      return;
    }
    // Interpola por el camino más corto desde lo que se muestra ahora.
    _from = _displayed;
    final delta = math.atan2(
      math.sin(target - _from),
      math.cos(target - _from),
    );
    _to = _from + delta;
    _displayed = target;
    _turn.forward(from: 0);
  }

  void _onTurnStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _displayed = _to;
  }

  /// Rumbo objetivo en radianes; `null` → arriba (0).
  double _targetRadians() => (widget.headingDegrees ?? 0) * math.pi / 180.0;

  @override
  void dispose() {
    _turn.removeStatusListener(_onTurnStatus);
    _turnCurve.dispose();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _TruckPainter(
      from: _from,
      to: _to,
      settled: _displayed,
      // El pintor repinta con el giro y toma el ángulo interpolado; si no corre
      // usa el ángulo fijo. Halo estático (sin latido).
      turn: _turnCurve,
    );
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: painter,
        isComplex: false,
        willChange: false,
        child: Semantics(
          label: 'Tu camión',
          image: true,
          child: SizedBox.square(dimension: widget.size),
        ),
      ),
    );
  }
}

/// Dibuja el camión top-down apuntando al rumbo sobre un halo claro ESTÁTICO
/// con sombra, para que nunca se pierda en el mapa. El ángulo mostrado es
/// [settled] salvo que el giro [turn] esté corriendo: ahí interpola [from]→[to]
/// con la curva, y repinta suscripto a [turn] (sin `setState` por frame).
class _TruckPainter extends CustomPainter {
  _TruckPainter({
    required this.from,
    required this.to,
    required this.settled,
    required this.turn,
  }) : super(repaint: turn);

  /// Extremos del giro en curso (radianes).
  final double from;
  final double to;

  /// Ángulo fijo cuando no hay giro corriendo (radianes).
  final double settled;

  /// Curva 0..1 del giro; cuando corre, interpola [from]→[to].
  final Animation<double> turn;

  double get _angle =>
      turn.isAnimating ? from + (to - from) * turn.value : settled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final s = size.shortestSide;

    // --- Halo + sombra ESTÁTICOS (sin latido por frame) ---
    final haloR = s * 0.44;

    // Sombra blanda DEBAJO del camión: lo despega de tiles oscuros.
    canvas.drawCircle(
      center.translate(0, s * 0.045),
      haloR * 0.96,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Glow blando claro (SIN disco ni aro): despega el camión del mapa oscuro
    // como el auto de Uber/inDrive, sin el feo círculo blanco con borde rojo.
    canvas.drawCircle(
      center,
      haloR * 0.9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // --- Camión rotado hacia el rumbo ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_angle); // horario; 0 = trompa arriba.
    _paintTruck(canvas, s);
    canvas.restore();
  }

  /// Furgón (box truck) visto DESDE ARRIBA apuntando hacia -Y (arriba), centrado
  /// en (0,0): cabina roja corta adelante + caja/contenedor carbón largo atrás,
  /// como un camión de reparto real (el ejemplo que pidió el dueño, en rojo).
  /// Simétrico a propósito para que al rotar con el rumbo NUNCA se vea torcido.
  void _paintTruck(Canvas canvas, double s) {
    // Caja carbón (como el contenedor gris del ejemplo) y azul del parabrisas.
    const boxColor = Color(0xFF3A3B3E);
    const boxEdge = Color(0xFF2A2B2D);
    const glassColor = Color(0xFFDCEBF4);

    final halfLen = s * 0.345; // mitad del largo (trompa → cola).
    final halfWid = s * 0.17; // mitad del ancho de la carrocería.
    final front = -halfLen; // trompa (adelante).
    final back = halfLen; // cola.
    final left = -halfWid;
    final right = halfWid;

    // Unión cabina/caja: la cabina ocupa ~28% del largo adelante.
    final cabBack = front + halfLen * 0.56;

    // --- Ruedas: rectángulos oscuros que asoman a los costados (eje delantero
    // bajo la cabina, eje trasero bajo la caja). Van primero (debajo). ---
    final wheel = Paint()..color = const Color(0xFF141414);
    final wheelW = s * 0.055;
    final wheelLen = s * 0.145;
    final wheelOut = halfWid + wheelW * 0.25;
    for (final cy in [front + halfLen * 0.42, back - halfLen * 0.34]) {
      for (final cx in [-wheelOut, wheelOut]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: wheelW * 2,
              height: wheelLen,
            ),
            Radius.circular(wheelW),
          ),
          wheel,
        );
      }
    }

    // --- Caja / contenedor (carbón), desde la unión hasta la cola ---
    final boxRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, cabBack, right, back),
      topLeft: Radius.circular(halfWid * 0.28),
      topRight: Radius.circular(halfWid * 0.28),
      bottomLeft: Radius.circular(halfWid * 0.5),
      bottomRight: Radius.circular(halfWid * 0.5),
    );
    canvas.drawRRect(boxRect, Paint()..color = boxColor);
    canvas.drawRRect(
      boxRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..color = boxEdge,
    );
    // Nervaduras del techo del contenedor (líneas finas a lo ancho).
    final rib = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    const ribCount = 3;
    for (var i = 1; i <= ribCount; i++) {
      final y = cabBack + (back - cabBack) * (i / (ribCount + 1));
      canvas.drawLine(
        Offset(left + halfWid * 0.22, y),
        Offset(right - halfWid * 0.22, y),
        rib,
      );
    }

    // --- Cabina roja de marca (adelante), con techo redondeado en la trompa ---
    final cabRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, front, right, cabBack + halfLen * 0.04),
      topLeft: Radius.circular(halfWid * 0.92),
      topRight: Radius.circular(halfWid * 0.92),
      bottomLeft: Radius.circular(halfWid * 0.2),
      bottomRight: Radius.circular(halfWid * 0.2),
    );
    canvas.drawRRect(cabRect, Paint()..color = AppColors.brand);
    canvas.drawRRect(
      cabRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..color = AppColors.brandDark,
    );

    // Parabrisas azulado cerca de la trompa (marca la dirección de avance).
    final windshield = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        left + halfWid * 0.32,
        front + halfLen * 0.14,
        right - halfWid * 0.32,
        front + halfLen * 0.36,
      ),
      Radius.circular(halfWid * 0.3),
    );
    canvas.drawRRect(windshield, Paint()..color = glassColor);

    // Faros: dos puntos claros en las esquinas de la trompa (refuerzan "hacia
    // dónde apunta" sin un chevron que se viera torcido al rotar).
    final headlight = Paint()..color = const Color(0xFFFFF3D6);
    final hlR = s * 0.028;
    for (final cx in [-halfWid * 0.55, halfWid * 0.55]) {
      canvas.drawCircle(Offset(cx, front + halfLen * 0.06), hlR, headlight);
    }
  }

  @override
  bool shouldRepaint(_TruckPainter old) =>
      old.settled != settled ||
      old.from != from ||
      old.to != to ||
      old.turn != turn;
}
