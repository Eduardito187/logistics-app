import 'package:flutter/material.dart';

import '../../../../core/theme/code_text.dart';

/// Fila de ícono + texto para mostrar un dato de la parada o la entrega.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.mono = false,
  });

  final IconData icon;
  final String text;

  /// Si el texto es un id/referencia (p. ej. la referencia del pedido), lo
  /// muestra en tipografía mono (IBM Plex Mono).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: mono ? CodeText(text) : Text(text)),
        ],
      ),
    );
  }
}
