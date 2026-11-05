import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/section_card.dart';
import 'line_draft.dart';

/// Editor de una línea del pedido (SKU, nombre, cantidad y piezas por unidad).
class LineEditor extends StatelessWidget {
  const LineEditor({
    super.key,
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final LineDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Línea ${index + 1}',
      trailing: canRemove
          ? IconButton(
              onPressed: onRemove,
              icon: const AnimatedAppIcon(AppIcon.delete),
              tooltip: 'Quitar línea',
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: draft.sku,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'SKU',
              prefixIcon: AnimatedAppIcon(AppIcon.qrCode),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del producto',
              prefixIcon: AnimatedAppIcon(AppIcon.receive),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.pieces,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Piezas/unidad'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
