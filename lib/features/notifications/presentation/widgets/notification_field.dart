import 'package:flutter/material.dart';

import '../../../../core/theme/code_text.dart';

/// Fila etiqueta/valor usada en el detalle de una notificación: la etiqueta en
/// gris a la izquierda y el valor resaltado alineado a la derecha. Ambos
/// textos se parten en varias líneas si no entran.
class NotificationField extends StatelessWidget {
  const NotificationField({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;

  /// Si el valor es un id/referencia (p. ej. la referencia del envío), lo
  /// muestra en tipografía mono (IBM Plex Mono); la etiqueta no cambia.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La etiqueta puede partirse (hasta 2/5 del ancho): con letra grande en
        // teléfonos chicos no le quita todo el lugar al valor ni desborda.
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: mono
                ? CodeText.mono(
                    theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ),
      ],
    );
  }
}
