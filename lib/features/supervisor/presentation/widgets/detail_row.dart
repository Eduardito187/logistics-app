import 'package:flutter/material.dart';

import '../../../../core/theme/code_text.dart';

/// Fila etiqueta/valor para los datos de cabecera de un plan.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;

  /// Si el valor es un id/código (p. ej. el id del plan), lo muestra en
  /// tipografía mono (IBM Plex Mono); las etiquetas nunca cambian.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
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
