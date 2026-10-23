import 'package:flutter/material.dart';

/// Placeholder con un barrido de brillo (shimmer) suave de izquierda a derecha.
///
/// Pensado para esqueletos de carga: ocupa el lugar del contenido real mientras
/// llega. Un solo [AnimationController] en bucle mueve un [LinearGradient] (base
/// → brillo más claro → base). Con "reducir movimiento" activo muestra un
/// contenedor liso del color base, sin controller ni animación.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 12,
  });

  /// Ancho fijo; `null` ocupa el ancho disponible del padre.
  final double? width;

  /// Alto fijo del bloque.
  final double height;

  /// Radio de las esquinas.
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  // Nulo mientras no sepamos si hay que animar: el controller se crea en
  // didChangeDependencies, cuando ya podemos leer MediaQuery (reducir mov.).
  AnimationController? _controller;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced == _reducedMotion && _controller != null) {
      return;
    }
    _reducedMotion = reduced;
    if (reduced) {
      // Reducir movimiento: sin animación, se libera cualquier controller.
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??=
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200),
          )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    // Brillo: mezcla hacia el surface/blanco para un resalte apenas perceptible.
    final highlight = Color.alphaBlend(
      scheme.surface.withValues(alpha: 0.6),
      base,
    );
    final radius = BorderRadius.circular(widget.borderRadius);
    final controller = _controller;

    if (controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // De -1 a 1: la banda de brillo entra por la izquierda y sale por la
        // derecha de forma continua.
        final t = controller.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}
