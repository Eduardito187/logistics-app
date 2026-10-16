import 'package:flutter/material.dart';

/// Fila etiqueta/valor usada en el detalle de una notificación: la etiqueta en
/// gris a la izquierda y el valor resaltado alineado a la derecha. Ambos
/// textos se parten en varias líneas si no entran.
class NotificationField extends StatelessWidget {
  const NotificationField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
