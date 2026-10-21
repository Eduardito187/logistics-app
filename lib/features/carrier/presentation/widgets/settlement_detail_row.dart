import 'package:flutter/material.dart';

import '../../../../core/theme/code_text.dart';

/// Fila etiqueta/valor del detalle de una liquidación.
class SettlementDetailRow extends StatelessWidget {
  const SettlementDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;

  /// Si el valor es un id/referencia (referencia de liquidación o de pago), lo
  /// muestra en tipografía mono (IBM Plex Mono); la etiqueta no cambia.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proporcional (2:3) en vez de un ancho fijo: en 320 dp con letra
          // grande el valor no queda aplastado.
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: mono
                  ? CodeText.mono(const TextStyle(fontWeight: FontWeight.w600))
                  : const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
