import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/scanning/scan_feedback.dart';
import '../../../../core/theme/high_contrast.dart';
import '../../../../core/widgets/section_card.dart';

/// Ajustes de uso en terreno: alto contraste para el sol y aviso al escanear.
/// Se guardan en el teléfono (no dependen de la cuenta ni de la red).
class FieldUseSection extends ConsumerWidget {
  const FieldUseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(highContrastProvider);
    final scanFeedback = ref.watch(scanFeedbackEnabledProvider);

    return SectionCard(
      title: 'Uso en terreno',
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('highContrastSwitch'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Alto contraste (sol)'),
            subtitle: const Text(
              'Fondo blanco y letra negra, más fácil de leer.',
            ),
            value: highContrast,
            onChanged: (value) =>
                ref.read(highContrastProvider.notifier).set(value),
          ),
          SwitchListTile(
            key: const Key('scanFeedbackSwitch'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibrar y sonar al escanear'),
            subtitle: const Text(
              'Confirma cada lectura sin mirar la pantalla.',
            ),
            value: scanFeedback,
            onChanged: (value) =>
                ref.read(scanFeedbackEnabledProvider.notifier).set(value),
          ),
        ],
      ),
    );
  }
}
