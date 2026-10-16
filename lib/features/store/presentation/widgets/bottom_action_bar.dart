import 'package:flutter/material.dart';

/// Botón de acción principal fijo al pie (escanear, entregar): siempre a mano
/// del pulgar, sin tener que scrollear. Los avisos de estas pantallas se
/// muestran con `bottomClearance: kBottomActionClearance` para flotar encima.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  /// Normalmente un `FilledButton.icon` (alto 56 desde el tema).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
