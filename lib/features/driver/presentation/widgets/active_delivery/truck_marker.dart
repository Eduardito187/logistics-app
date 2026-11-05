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

  /// Camión visto desde arriba apuntando hacia -Y (arriba), centrado en (0,0).
  void _paintTruck(Canvas canvas, double s) {
    // Silueta: largo > ancho para que se lea como camión y hacia dónde apunta.
    final halfLen = s * 0.30; // mitad del largo (de trompa a cola).
    final halfWid = s * 0.165; // mitad del ancho de la carrocería.
    final top = -halfLen; // trompa (adelante).
    final bottom = halfLen; // cola.
    final left = -halfWid;
    final right = halfWid;

    // Ruedas: rectángulos oscuros que asoman a los costados (realismo Uber).
    final wheel = Paint()..color = const Color(0xFF1A1A1A);
    final wheelW = s * 0.05;
    final wheelLen = s * 0.12;
    final wheelOut = halfWid + wheelW * 0.35;
    for (final cy in [top + halfLen * 0.55, bottom - halfLen * 0.45]) {
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

    // Carrocería roja de marca, puntas redondeadas (la trompa un poco más).
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, top, right, bottom),
      topLeft: Radius.circular(halfWid * 0.95),
      topRight: Radius.circular(halfWid * 0.95),
      bottomLeft: Radius.circular(halfWid * 0.55),
      bottomRight: Radius.circular(halfWid * 0.55),
    );
    canvas.drawRRect(bodyRect, Paint()..color = AppColors.brand);
    // Borde interno más oscuro para dar volumen.
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..color = AppColors.brandDark,
    );

    // Caja/furgón: franja trasera algo más oscura (cabina al frente, caja
    // atrás), separada por la línea de techo blanca.
    final boxTop = top + halfLen * 0.78;
    final boxRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, boxTop, right, bottom),
      bottomLeft: Radius.circular(halfWid * 0.55),
      bottomRight: Radius.circular(halfWid * 0.55),
    );
    canvas.save();
    canvas.clipRRect(bodyRect);
    canvas.drawRRect(boxRect, Paint()..color = AppColors.brandDark);
    canvas.restore();

    // Parabrisas blanco cerca de la trompa (marca la dirección).
    final windshield = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        left + halfWid * 0.42,
        top + halfLen * 0.20,
        right - halfWid * 0.42,
        top + halfLen * 0.52,
      ),
      Radius.circular(halfWid * 0.35),
    );
    canvas.drawRRect(windshield, Paint()..color = Colors.white);

    // Línea de techo blanca que separa cabina de la caja.
    canvas.drawLine(
      Offset(left + halfWid * 0.2, boxTop),
      Offset(right - halfWid * 0.2, boxTop),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = s * 0.02,
    );

    // Chevron blanco en la trompa: refuerza "hacia dónde apunta".
    final chevron = Path()
      ..moveTo(-halfWid * 0.5, top + halfLen * 0.10)
      ..lineTo(0, top - halfLen * 0.02)
      ..lineTo(halfWid * 0.5, top + halfLen * 0.10);
    canvas.drawPath(
      chevron,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_TruckPainter old) =>
      old.settled != settled ||
      old.from != from ||
      old.to != to ||
      old.turn != turn;
}
