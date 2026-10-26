import 'package:flutter/material.dart';

import 'brand_splash.dart';

/// Host de arranque: muestra el splash animado [BrandSplash] UNA sola vez y
/// después entrega [app] (la MaterialApp real) para siempre.
///
/// Es un `StatefulWidget` creado una única vez en `runApp` (NO dentro del
/// `builder` de MaterialApp, que se reconstruye en cada cambio de tema/estado).
/// Así el Lottie se crea y decodifica una sola vez y nunca vuelve a correr al
/// navegar: evita el consumo de CPU por recrear la animación en cada página.
class BootSplashGate extends StatefulWidget {
  const BootSplashGate({super.key, required this.app});

  /// La app real (una MaterialApp), que se muestra al terminar el splash.
  final Widget app;

  @override
  State<BootSplashGate> createState() => _BootSplashGateState();
}

class _BootSplashGateState extends State<BootSplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.app;
    // MaterialApp mínima solo para alojar el splash (Directionality/MediaQuery).
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color(0xFF141414),
      home: BrandSplash(
        onDone: () {
          if (mounted) setState(() => _done = true);
        },
      ),
    );
  }
}
