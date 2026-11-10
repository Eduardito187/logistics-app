import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../driver_route_status.dart';

/// Pin tipo "gota"/teardrop reutilizable para los marcadores del mapa: cuerpo
/// coloreado, aro blanco, sombra suave y la punta hacia abajo (apunta a la
/// coordenada). El `child` va centrado en la parte circular.
///
/// La punta queda en el borde inferior-centro, así que el `Marker` que lo use
/// debe fijar `alignment: Alignment.topCenter` para clavar la punta en el
/// punto geográfico.
class TeardropPin extends StatelessWidget {
  const TeardropPin({
    super.key,
    required this.color,
    required this.child,
    this.size = 40,
    this.ringColor = Colors.white,
    this.glow = false,
  });

  /// Color de relleno del pin.
  final Color color;

  /// Contenido centrado en el círculo (número, ícono…).
  final Widget child;

  /// Diámetro de la parte circular en dp. El alto total es [heightFor].
  final double size;

  /// Color del aro.
  final Color ringColor;

  /// Glow exterior tenue del color del pin (para el destino destacado).
  final bool glow;

  /// Alto total de un pin de círculo [size] (la punta suma ≈32%).
  static double heightFor(double size) => size * 1.32;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(size);
    return SizedBox(
      width: size,
      height: height,
      child: CustomPaint(
        painter: _TeardropPainter(color: color, ring: ringColor, glow: glow),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  _TeardropPainter({
    required this.color,
    required this.ring,
    required this.glow,
  });

  final Color color;
  final Color ring;
  final bool glow;

  Path _teardrop(Size size) {
    final w = size.width;
    final r = w / 2;
    final cx = w / 2;
    final cy = r; // centro del círculo
    final h = size.height; // punta
    return Path()
      ..moveTo(cx, h)
      ..cubicTo(cx - r * 0.18, cy + r * 0.95, cx - r, cy + r * 0.55, cx - r, cy)
      ..arcToPoint(
        Offset(cx + r, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..cubicTo(cx + r, cy + r * 0.55, cx + r * 0.18, cy + r * 0.95, cx, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _teardrop(size);

    // Glow exterior opcional (destino destacado).
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..isAntiAlias = true,
      );
    }

    // Sombra suave.
    canvas.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..isAntiAlias = true,
    );

    // Relleno.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );

    // Aro blanco.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_TeardropPainter old) =>
      old.color != color || old.ring != ring || old.glow != glow;
}

/// Marcador de una parada en el mapa: pin teardrop con el número de secuencia,
/// coloreado según el estado de la parada ([stopColor]).
class StopPin extends StatelessWidget {
  const StopPin({super.key, required this.stop, this.size = 40});

  final DriverRouteStop stop;

  /// Diámetro del círculo del pin en dp.
  final double size;

  /// Alto total del pin (para dimensionar el `Marker`).
  static double heightFor(double size) => TeardropPin.heightFor(size);

  @override
  Widget build(BuildContext context) {
    return TeardropPin(
      color: stopColor(stop.status),
      size: size,
      child: Text(
        '${stop.sequence}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
  }
}
