import 'package:flutter/material.dart';

/// Envuelve el contenido de un bottom sheet de fondo TRANSPARENTE para que tocar
/// el área de afuera (el scrim semitransparente que rodea la tarjeta) cierre el
/// sheet, como en el resto del sistema.
///
/// Por qué hace falta: un `showModalBottomSheet(backgroundColor:
/// Colors.transparent)` con `isScrollControlled: true` y un `Align` ocupa TODA
/// la pantalla, así que el espacio vacío alrededor de la tarjeta es parte del
/// sheet (no del barrier de atrás) y, sin esto, tocarlo no cerraría.
///
/// El contenido ([child], la tarjeta) absorbe sus propios toques: tocar la
/// tarjeta —o sus botones— NO cierra; solo cierra tocar fuera de ella.
class TapOutsideToDismiss extends StatelessWidget {
  const TapOutsideToDismiss({
    super.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Toque en el área de afuera (transparente) → cerrar.
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          // Absorbe los toques sobre la tarjeta para que NO lleguen al cierre
          // (sus botones/links siguen funcionando: ganan el gesto por ser más
          // específicos; este `onTap` solo captura el fondo de la tarjeta).
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}
