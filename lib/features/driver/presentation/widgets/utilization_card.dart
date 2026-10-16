import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/driver_controllers.dart';

/// Indicadores de utilización del vehículo en los últimos 30 días.
class UtilizationCard extends ConsumerWidget {
  const UtilizationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilization = ref.watch(vehicleUtilizationProvider);
    return SectionCard(
      title: 'Utilización (últimos 30 días)',
      child: AsyncValueView<Map<String, Object?>>(
        value: utilization,
        onRetry: () => ref.invalidate(vehicleUtilizationProvider),
        data: (data) {
          if (data.isEmpty) {
            return const Text('Sin datos de utilización disponibles.');
          }
          return Column(
            children: [
              for (final entry in data.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_humanize(entry.key))),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _humanize(String key) => key.replaceAll('_', ' ').replaceAll('-', ' ');
}
