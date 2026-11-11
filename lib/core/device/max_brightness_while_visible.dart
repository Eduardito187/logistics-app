import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screen_brightness_service.dart';

/// Sube el brillo al máximo mientras [child] está en pantalla (un QR que otro
/// tiene que escanear) y lo devuelve al cerrarse. Envolver SOLO el QR, no
/// pantallas enteras: el brillo alto gasta batería.
///
/// Si la app pasa a segundo plano el sistema ya restituye el brillo propio;
/// al volver se vuelve a subir.
class MaxBrightnessWhileVisible extends ConsumerStatefulWidget {
  const MaxBrightnessWhileVisible({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MaxBrightnessWhileVisible> createState() =>
      _MaxBrightnessWhileVisibleState();
}

class _MaxBrightnessWhileVisibleState
    extends ConsumerState<MaxBrightnessWhileVisible> {
  late final ScreenBrightnessService _service;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _service = ref.read(screenBrightnessServiceProvider);
    unawaited(_service.boost());
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_service.boost()),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_service.restore());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
