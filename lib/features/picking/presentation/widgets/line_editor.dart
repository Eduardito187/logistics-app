import 'package:flutter/material.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Línea ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Quitar línea',
                ),
            ],
          ),
          TextField(
            controller: draft.sku,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'SKU',
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del producto',
              prefixIcon: Icon(Icons.inventory_2),
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
