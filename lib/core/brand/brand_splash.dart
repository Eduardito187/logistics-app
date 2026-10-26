import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Splash animado de marca DisTrack (Lottie, ~2,2 s). Arranca con el isotipo ya
/// armado en el mismo lugar que el splash nativo del sistema (fondo Noche
/// `#141414`), así no hay salto entre uno y otro.
///
/// Reproduce la animación UNA sola vez y llama a [onDone] al terminar. Con
/// `prefers-reduced-motion` activo muestra directo el último fotograma (sin
/// animar). Tiene una salvaguarda: si el Lottie no carga o tarda, [onDone] se
/// dispara igual al vencer [_maxDuration], así la app NUNCA queda trabada en el
/// splash.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, this.onDone});

  /// Se invoca cuando la animación termina (o por la salvaguarda). Idempotente.
  final VoidCallback? onDone;

  static const Color _night = Color(0xFF141414);
  static const String _asset = 'assets/brand/splash-animation.json';

  /// Tope duro: pase lo que pase con el Lottie, se continúa a la app.
  static const Duration _maxDuration = Duration(seconds: 3);

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Timer? _failsafe;
  bool _done = false;
  bool _started = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    // Salvaguarda: si el Lottie no termina (asset ausente, carga lenta), se
    // continúa igual al vencer el tope.
    _failsafe = Timer(BrandSplash._maxDuration, _finish);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.of(context).disableAnimations;
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _failsafe?.cancel();
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _failsafe?.cancel();
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
          // Si el asset no se puede decodificar, no se queda colgado: la
          // salvaguarda igual dispara onDone.
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            // Lottie puede volver a invocar `onLoaded` si el widget se
            // reconstruye (p. ej. el `builder` de MaterialApp recrea el gate
            // durante el arranque): arrancar `forward()` de nuevo reiniciaría la
            // animación y volvería a decodificar en el hilo principal. Se
            // arranca una sola vez.
            if (_started) return;
            _started = true;
            if (_reducedMotion) {
              // reduced-motion: último fotograma fijo, sin animar.
              _controller.value = 1;
              _finish();
            } else {
              _controller.forward().whenComplete(_finish);
            }
          },
        ),
      ),
    );
  }
}
