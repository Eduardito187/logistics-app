import 'package:flutter/material.dart';

/// Confirma la conciliación de una recepción; devuelve `true` al aceptar.
/// Con diferencias, avisa cuántos faltantes y sobrantes quedan registrados.
class ReconcileConfirmDialog extends StatelessWidget {
  const ReconcileConfirmDialog({
    super.key,
    required this.pending,
    required this.surplus,
  });

  final int pending;
  final int surplus;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conciliar recepción'),
      content: Text(
        pending == 0 && surplus == 0
            ? 'Todo coincide con el manifiesto. Se cerrará la recepción.'
            : 'Se cerrará la recepción con $pending faltante(s) y '
                  '$surplus sobrante(s). Esta acción queda registrada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Conciliar'),
        ),
      ],
    );
  }
}
