import 'package:flutter/material.dart';

import '../icons/icons.dart';

/// Tiempo sin leer ningún código tras el cual la cámara del escáner se pausa.
///
/// Por qué (batería): cámara + análisis de códigos es de lo más caro que hace
/// un teléfono (comparable a un juego pesado). Si el escáner queda abierto
/// sobre la mesa o en el bolsillo, se pausa solo; un toque lo retoma.
const Duration kScannerIdlePause = Duration(seconds: 60);

/// Capa que tapa la vista de la cámara pausada por inactividad: botón grande
/// (se usa con guantes) para seguir escaneando.
class ScannerPausedOverlay extends StatelessWidget {
  const ScannerPausedOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedAppIcon(
                  AppIcon.scan,
                  size: 56,
                  color: Colors.white,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cámara en pausa para ahorrar batería',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: onResume,
                    child: const Text(
                      'Seguir escaneando',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
