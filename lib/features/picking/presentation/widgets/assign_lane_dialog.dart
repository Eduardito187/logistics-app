import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/scanning/scanner_screen.dart';

/// Diálogo para asignar/cambiar el carril o vehículo de carga. Devuelve el valor
/// ingresado sin espacios (o null si se cancela o se guarda vacío) mediante
/// `Navigator.pop`.
class AssignLaneDialog extends StatefulWidget {
  const AssignLaneDialog({super.key, this.initial});

  final String? initial;

  @override
  State<AssignLaneDialog> createState() => _AssignLaneDialogState();
}

class _AssignLaneDialogState extends State<AssignLaneDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await scanCode(
      context,
      title: 'Escanear carril',
      helper: 'Apuntá al código del carril o del vehículo.',
      formats: const <BarcodeFormat>[
        BarcodeFormat.code128,
        BarcodeFormat.qrCode,
      ],
    );
    if (!mounted || code == null) return;
    _controller.text = code;
  }

  void _save() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Carril / vehículo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Ej. Carril 3 / ABC-123',
              prefixIcon: Icon(Icons.alt_route),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
