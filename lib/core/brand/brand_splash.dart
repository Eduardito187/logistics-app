import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Splash animado de marca DisTrack (Lottie, ~2,2 s). Arranca con el isotipo ya
/// armado en el mismo lugar que el splash nativo del sistema (fondo Noche
/// `#141414`), así no hay salto entre uno y otro.
///
/// Reproduce la animación una sola vez y llama a [onDone] al terminar. Con
/// `prefers-reduced-motion` activo muestra directo el último fotograma (sin
/// animar), según el kit de marca.
///
/// NOTA: no está cableado al arranque por defecto (el splash nativo ya cubre el
/// cold start). Para usarlo, mostrarlo como pantalla inicial mientras la app
/// termina de inicializar y navegar en [onDone].
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, this.onDone});

  /// Se invoca cuando la animación termina (o de inmediato en reduced-motion).
  final VoidCallback? onDone;

  static const Color _night = Color(0xFF141414);
  static const String _asset = 'assets/brand/splash-animation.json';

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandSplash._night,
      child: Center(
        child: Lottie.asset(
          BrandSplash._asset,
          controller: _controller,
          repeat: false,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            if (_reducedMotion) {
              // reduced-motion: último fotograma fijo, sin animar.
              _controller.value = 1;
              widget.onDone?.call();
            } else {
              _controller.forward().whenComplete(() => widget.onDone?.call());
            }
          },
        ),
      ),
    );
  }
}
