import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Loader de marca: el isotipo DisTrack con un pulso suave de escala y opacidad,
/// centrado, con un mensaje opcional debajo.
///
/// Elige la variante del SVG según el brillo del tema (claro → isotipo oscuro;
/// Noche → isotipo invertido). Con "reducir movimiento" activo muestra el
/// isotipo estático, sin controller. Si el SVG fallara, cae a un
/// [CircularProgressIndicator] en color de marca.
class BrandLoader extends StatefulWidget {
  const BrandLoader({super.key, this.size = 56, this.message});

  /// Lado del isotipo en píxeles lógicos.
  final double size;

  /// Texto opcional debajo del isotipo (p. ej. "Cargando ruta...").
  final String? message;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  static const String _light = 'assets/brand/distrack-mark.svg';
  static const String _dark = 'assets/brand/distrack-mark-inverse.svg';

  // Nulo con reducir movimiento: no se crea ningún controller.
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
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??=
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1100),
          )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mark = SvgPicture.asset(
      isDark ? _dark : _light,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      semanticsLabel: 'DisTrack',
      // Si el asset no cargara, un indicador clásico en rojo de marca.
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      ),
    );

    final controller = _controller;
    final Widget animated;
    if (controller == null) {
      // Reducir movimiento: isotipo estático a tamaño/opacidad plenos.
      animated = mark;
    } else {
      animated = AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final v = controller.value;
          return Opacity(
            opacity: 0.6 + 0.4 * v,
            child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
          );
        },
        child: mark,
      );
    }

    return Semantics(
      label: widget.message ?? 'Cargando',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          animated,
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
