import 'package:flutter/material.dart';

/// Pide dónde se guardó lo recibido. Se muestra UNA vez al terminar la ráfaga
/// de escaneo continuo y la ubicación se aplica a todos los productos de esa
/// ráfaga ([count]): una entrega suele ir junta al mismo estante, y abrir un
/// diálogo por producto cortaría el escaneo continuo.
///
/// Es dueño de su controller: liberarlo apenas vuelve `showDialog` fallaba
/// porque el diálogo todavía anima al cerrarse y sigue usando el TextField
/// ("used after being disposed").
class ShelfLocationDialog extends StatefulWidget {
  const ShelfLocationDialog({super.key, this.count = 1});

  /// Cantidad de productos a los que se aplica la ubicación.
  final int count;

  @override
  State<ShelfLocationDialog> createState() => _ShelfLocationDialogState();
}

class _ShelfLocationDialogState extends State<ShelfLocationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    return AlertDialog(
      title: const Text('Ubicación en estante'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count > 1) ...[
            Text('Para los $count productos recién recibidos.'),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Dónde se guardó',
              hintText: 'Ej. Pasillo 3 · Estante B2',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Omitir'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
