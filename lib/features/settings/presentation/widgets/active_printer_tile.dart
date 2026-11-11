import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/print_result_message.dart';
import 'printer_summary.dart';

/// La impresora activa en grande: ícono del transporte, nombre, resumen y
/// pastilla de estado (No responde si la última prueba falló).
class ActivePrinterTile extends StatelessWidget {
  const ActivePrinterTile({
    required this.printer,
    required this.lastResult,
    super.key,
  });

  final PrinterConfig printer;
  final PrintResultMessage? lastResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failing = lastResult?.tone == PrintResultTone.error;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AnimatedAppIcon(
            printerTransportIcon(printer.transport),
            size: 30,
            color: scheme.primary,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                printer.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                printerSummary(printer),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              failing
                  ? const StatusPill(
                      'No responde',
                      tone: PillTone.danger,
                      icon: AppIcon.error,
                    )
                  : const StatusPill(
                      'Lista',
                      tone: PillTone.success,
                      icon: AppIcon.check,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
