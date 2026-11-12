import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/printer_detection.dart';
import '../controllers/print_test_controller.dart';
import 'print_result_text.dart';
import 'printer_credentials_prompt.dart';
import 'printer_summary.dart';

/// Paso 3 del asistente, "Listo": check animado, nombre de la impresora,
/// "Imprimir prueba" y "Terminar".
///
/// Si la detección dice que es de oficina y pide usuario, aparece SOLO lo
/// necesario (usuario y contraseña, "Guardar y probar"). Zebra: nada más.
class PrinterDoneStep extends ConsumerWidget {
  const PrinterDoneStep({
    required this.printer,
    required this.onFinish,
    this.detecting = false,
    this.detection,
    this.defaultUser,
    super.key,
  });

  final PrinterConfig printer;
  final VoidCallback onFinish;

  /// Revisando qué tipo de impresora es (solo WiFi nueva).
  final bool detecting;
  final PrinterDetection? detection;
  final String? defaultUser;

  /// La impresora pide usuario: hay que mostrar el formulario corto.
  bool get needsCredentials =>
      printer.transport == PrinterTransport.wifi &&
      printer.isOffice &&
      (detection?.requiresCredentials ?? false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final test = ref.watch(printTestControllerProvider);
    final lastResult = test.lastResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AnimatedAppIcon(
            AppIcon.success,
            state: AppIconState.success,
            size: 72,
            color: scheme.primary,
            animateOnMount: true,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            '¡Impresora conectada!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          printer.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          printerSummary(printer),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (detecting)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedAppIcon(
                AppIcon.search,
                state: AppIconState.loading,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: const Text('Revisando la impresora…'),
                ),
              ),
            ],
          )
        else if (needsCredentials)
          PrinterCredentialsPrompt(
            address: printer.address,
            defaultUser: defaultUser,
            busy: test.printing,
            onSaved: () => runPrintTest(context, ref),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: test.printing ? null : () => runPrintTest(context, ref),
            icon: AnimatedAppIcon(
              AppIcon.printing,
              state: test.printing ? AppIconState.loading : AppIconState.idle,
              semanticLabel: test.printing ? 'Imprimiendo' : 'Imprimir',
            ),
            label: const Text('Imprimir prueba'),
          ),
        if (lastResult != null) ...[
          const SizedBox(height: 12),
          PrintResultText(lastResult),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: onFinish,
          icon: const AnimatedAppIcon(
            AppIcon.check,
            excludeFromSemantics: true,
          ),
          label: const Text('Terminar'),
        ),
      ],
    );
  }
}
