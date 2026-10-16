import 'package:flutter/material.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import 'button_spinner.dart';

/// Fila de una unidad del pedido: SKU, bulto y estado, con la acción de escanear
/// e imprimir (si está pendiente) o reimprimir (si ya está preparada).
class UnitTile extends StatelessWidget {
  const UnitTile({
    super.key,
    required this.label,
    required this.prepared,
    required this.busy,
    required this.onPrepare,
    required this.onReprint,
  });

  final EmittedLabel label;
  final bool prepared;
  final bool busy;
  final VoidCallback onPrepare;
  final VoidCallback onReprint;

  /// Ancho de contenido por debajo del cual el estado va bajo el SKU.
  static const double _stackBelow = 340;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = label.labelId.length > 8
        ? label.labelId.substring(label.labelId.length - 8)
        : label.labelId;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SKU ${label.sku}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Línea ${label.lineNumber} · Bulto …$shortId',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              );
              final pill = prepared
                  ? const StatusPill(
                      'Preparada',
                      tone: PillTone.success,
                      icon: Icons.check,
                    )
                  : const StatusPill('Pendiente', icon: Icons.schedule);
              // Angosto (teléfono chico, letra grande, columna de tablet): el
              // estado va debajo y el SKU usa todo el ancho.
              if (constraints.maxWidth < _stackBelow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 8), pill],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 8),
                  pill,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (prepared)
            OutlinedButton.icon(
              onPressed: busy ? null : onReprint,
              icon: busy ? const ButtonSpinner() : const Icon(Icons.print),
              label: const Text('Reimprimir etiqueta'),
            )
          else
            FilledButton.icon(
              onPressed: busy ? null : onPrepare,
              icon: busy
                  ? const ButtonSpinner()
                  : const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear EAN e imprimir'),
            ),
        ],
      ),
    );
  }
}
