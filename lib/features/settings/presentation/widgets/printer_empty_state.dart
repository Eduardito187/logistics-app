import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/status_pill.dart';

/// Sin impresora: estado vacío amable con un solo botón grande.
class PrinterEmptyState extends StatelessWidget {
  const PrinterEmptyState({required this.onConnect, super.key});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AnimatedAppIcon(
            AppIcon.printing,
            size: 56,
            color: theme.colorScheme.primary,
            animateOnMount: true,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Todavía no hay impresora',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Conectala una vez y queda guardada en este teléfono.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: StatusPill('Sin configurar', tone: PillTone.neutral),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: onConnect,
          icon: const AnimatedAppIcon(AppIcon.add, excludeFromSemantics: true),
          label: const Text('Conectar impresora'),
        ),
      ],
    );
  }
}
