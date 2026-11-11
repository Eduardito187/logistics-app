import 'package:flutter/material.dart';

import '../../../../core/power/motion_budget.dart';
import '../../../../core/theme/app_colors.dart';

/// Radar/pulso reutilizable: anillos concéntricos que se expanden y se
/// desvanecen, al estilo de las apps de parking. Se coloca DEBAJO del camión
/// (centrado en su posición) para marcar el fix en vivo.
///
/// Rendimiento (teléfonos de gama baja, en campo): un ÚNICO
/// `AnimationController` lento (2,5 s) alimenta los tres anillos escalonados;
/// el `CustomPainter` solo traza círculos. Con reduce-motion
/// (`MediaQuery.disableAnimationsOf`) o con ahorro de energía / batería baja
/// ([MotionBudget]) queda ESTÁTICO: dos anillos tenues fijos, sin controlador
/// en marcha. El pulso es decorativo y, sobre el mapa oscuro (capa con filtro
/// de color), cada cuadro animado obliga a recomponer la pantalla entera.
///
/// Pulso de 1,2 s (antes 2,5 s): con una lectura de GPS cada 15 s el radar
/// anima ~8 % del tiempo en vez de ~25 %.
class RadarPulse extends StatefulWidget {
  const RadarPulse({
    super.key,
    this.size = 120,
    this.color = AppColors.brand,
    this.trigger,
  });

  /// Lado del área del radar en dp (el diámetro máximo del anillo exterior).
  final double size;

  /// Color de los anillos (marca por defecto).
  final Color color;

  /// Dispara un "ping" cada vez que cambia (p. ej. la posición del camión en
  /// cada fix del GPS). Un pulso es FINITO a propósito: un `repeat()` infinito
  /// recalienta en campo (gama baja) y cuelga `pumpAndSettle` en los tests. Así
  /// el radar late con cada fix (cada pocos segundos) y queda quieto entre uno
  /// y otro.
  final Object? trigger;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _reduce = false;
  bool _systemReduce = false;

  @override
  void initState() {
    super.initState();
    MotionBudget.powerSaving.addListener(_onPowerChanged);
  }

  /// Ahorro de energía activado/desactivado en caliente.
  void _onPowerChanged() {
    if (!mounted) return;
    setState(_syncReduce);
  }

  void _syncReduce() {
    _reduce = _systemReduce || !MotionBudget.decorativeAllowed;
    if (_reduce) _controller.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReduce = MediaQuery.disableAnimationsOf(context);
    _syncReduce();
    if (!_reduce && !_controller.isAnimating && _controller.value == 0) {
      // Primer ping al aparecer el camión.
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RadarPulse old) {
    super.didUpdateWidget(old);
    // Nuevo fix del GPS → otro ping (finito).
    if (!_reduce && widget.trigger != old.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    MotionBudget.powerSaving.removeListener(_onPowerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Size.square(widget.size);
    if (_reduce) {
      return CustomPaint(
        size: size,
        painter: _RadarPainter(progress: null, color: widget.color),
      );
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: _RadarPainter(progress: _controller, color: widget.color),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress, required this.color})
    : super(repaint: progress);

  /// Fase global del radar (0..1). `null` = estático (reduce-motion).
  final Animation<double>? progress;
  final Color color;

  /// Anillos concéntricos escalonados.
  static const int _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Núcleo tenue fijo bajo el camión.
    canvas.drawCircle(
      center,
      maxR * 0.14,
      Paint()..color = color.withValues(alpha: 0.18),
    );

    if (progress == null) {
      // Estático: dos anillos tenues a radios fijos (sin animar).
      for (final f in const [0.45, 0.8]) {
        canvas.drawCircle(
          center,
          maxR * f,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..isAntiAlias = true
            ..color = color.withValues(alpha: 0.22 * (1 - f)),
        );
      }
      return;
    }

    final base = progress!.value;
    for (var i = 0; i < _rings; i++) {
      final t = (base + i / _rings) % 1.0;
      final r = maxR * t;
      if (r <= 0.5) continue;
      // Se desvanece a medida que se expande.
      final alpha = 0.38 * (1 - t);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = true
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.color != color || old.progress != progress;
}
