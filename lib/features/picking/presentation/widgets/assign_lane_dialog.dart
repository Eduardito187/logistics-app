import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/field_icon.dart';

/// Diálogo para asignar/cambiar el vehículo de reparto de un pedido preparado.
/// Devuelve la placa/puerta ingresada sin espacios (o null si se cancela o se
/// guarda vacío) mediante `Navigator.pop`.
///
/// Sin escaneo a propósito: los camiones y las puertas de carga de Dismac NO
/// tienen etiqueta de código, así que la placa se escribe a mano.
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

  void _save() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vehículo de reparto'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Placa o puerta de carga',
          hintText: 'Ej. 1234-ABC',
          prefixIconConstraints: FieldIcon.prefixConstraints,
          prefixIcon: FieldIcon(icon: AppIcon.plans),
        ),
        onSubmitted: (_) => _save(),
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
