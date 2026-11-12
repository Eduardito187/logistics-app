import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

/// Confirmación antes de elegir una impresora de red que NO es Zebra (Ricoh,
/// HP…): la app imprime ZPL y una láser de oficina lo sacaría como texto.
/// Devuelve `true` (Usar igual) o `false` (Cancelar / tocar afuera).
class NonZebraPrinterDialog extends StatelessWidget {
  const NonZebraPrinterDialog({required this.printerName, super.key});

  final String printerName;

  /// Muestra el diálogo; `true` solo si el operario elige "Usar igual".
  static Future<bool> confirm(BuildContext context, String printerName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NonZebraPrinterDialog(printerName: printerName),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const AnimatedAppIcon(
        AppIcon.incident,
        state: AppIconState.active,
        size: 40,
      ),
      title: const Text('¿No es una Zebra?'),
      content: Text(
        '$printerName no parece una impresora de etiquetas Zebra. Si la '
        'elegís, las etiquetas pueden salir como texto. ¿Usarla igual?',
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Usar igual'),
        ),
      ],
    );
  }
}
