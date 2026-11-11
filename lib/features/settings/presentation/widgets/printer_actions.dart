import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

/// "Imprimir prueba" y "Cambiar": lado a lado si entran, uno sobre otro en
/// teléfonos angostos o con letra grande. Ambos de 56 dp.
class PrinterActions extends StatelessWidget {
  const PrinterActions({
    required this.printing,
    required this.onPrintTest,
    required this.onChange,
    super.key,
  });

  final bool printing;
  final VoidCallback onPrintTest;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final print = FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
      onPressed: printing ? null : onPrintTest,
      // Mientras imprime, la hoja sale de la impresora (loop de loading).
      icon: AnimatedAppIcon(
        AppIcon.printing,
        state: printing ? AppIconState.loading : AppIconState.idle,
        semanticLabel: printing ? 'Imprimiendo' : 'Imprimir',
      ),
      label: const Text('Imprimir prueba'),
    );
    final change = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
      onPressed: onChange,
      icon: const AnimatedAppIcon(AppIcon.swap, excludeFromSemantics: true),
      label: const Text('Cambiar'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) >=
            340;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [print, const SizedBox(height: 8), change],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: print),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: change),
          ],
        );
      },
    );
  }
}
