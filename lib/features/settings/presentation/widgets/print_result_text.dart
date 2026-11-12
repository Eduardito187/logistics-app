import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../controllers/print_result_message.dart';

/// Resultado de la última prueba, en una línea con ícono: verde si la
/// impresora confirmó, neutro si no confirma (9100) y rojo con el motivo si
/// falló.
class PrintResultText extends StatelessWidget {
  const PrintResultText(this.result, {super.key});

  final PrintResultMessage result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, state, color) = switch (result.tone) {
      PrintResultTone.ok => (
        AppIcon.success,
        AppIconState.success,
        scheme.primary,
      ),
      PrintResultTone.unconfirmed => (
        AppIcon.pending,
        AppIconState.idle,
        scheme.onSurface,
      ),
      PrintResultTone.error => (
        AppIcon.error,
        AppIconState.error,
        scheme.error,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedAppIcon(
            icon,
            state: state,
            size: 20,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
