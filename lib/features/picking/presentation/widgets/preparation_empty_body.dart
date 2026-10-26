import 'package:flutter/material.dart';

import '../../../../core/layout/responsive_body.dart';
import '../../../../core/widgets/empty_state.dart';
import 'button_spinner.dart';

/// Cuerpo del armado cuando el pedido no tiene etiquetas vigentes: estado
/// vacío y el botón "Emitir etiquetas".
///
/// El botón queda fijo al pie: en un teléfono chico con letra grande el
/// estado vacío ocupa toda la pantalla y la acción quedaba fuera de vista.
class PreparationEmptyBody extends StatelessWidget {
  const PreparationEmptyBody({
    super.key,
    required this.busy,
    required this.onEmit,
  });

  /// Hay una operación de pedido en curso (deshabilita el botón).
  final bool busy;
  final VoidCallback onEmit;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmptyState(
                  icon: Icons.label_off,
                  title: 'Sin etiquetas vigentes',
                  message:
                      'Este pedido todavía no tiene etiquetas emitidas para '
                      'preparar.',
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: busy ? null : onEmit,
              icon: busy ? const ButtonSpinner() : const Icon(Icons.new_label),
              label: const Text('Emitir etiquetas'),
            ),
          ),
        ],
      ),
    );
  }
}
