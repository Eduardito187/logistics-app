import 'package:flutter/material.dart';

/// Pide dónde se guardó el bulto. Es dueño de su controller: liberarlo apenas
/// vuelve `showDialog` fallaba porque el diálogo todavía anima al cerrarse y
/// sigue usando el TextField ("used after being disposed").
class ShelfLocationDialog extends StatefulWidget {
  const ShelfLocationDialog({super.key});

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
    return AlertDialog(
      title: const Text('Ubicación en estante'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Dónde se guardó',
          hintText: 'Ej. Pasillo 3 · Estante B2',
        ),
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
