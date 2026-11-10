import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/field_icon.dart';
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
      title: 'Escanear vehículo',
      helper: 'Apuntá al código del vehículo o de la puerta de carga.',
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
      title: const Text('Vehículo de reparto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Placa o puerta de carga',
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(icon: AppIcon.plans),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const AnimatedAppIcon(AppIcon.scan),
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
