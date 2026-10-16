import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/fleet_ops_controllers.dart';

/// Lecturas de odómetro recientes del vehículo.
class RecentReadings extends ConsumerWidget {
  const RecentReadings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(vehicleOdometerReadingsProvider);
    return SectionCard(
      title: 'Lecturas recientes',
      child: AsyncValueView<List<OdometerReading>>(
        value: readings,
        onRetry: () => ref.invalidate(vehicleOdometerReadingsProvider),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.speed,
              title: 'Sin lecturas registradas',
              message: 'Las lecturas que registres aparecerán aquí.',
            );
          }
          final dateFormat = DateFormat('d MMM, HH:mm', 'es');
          final numberFormat = NumberFormat.decimalPattern('es');
          return Column(
            children: [
              for (final reading in items.take(10))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.speed, color: AppColors.info),
                  title: Text(
                    '${numberFormat.format(reading.km)} km',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(dateFormat.format(reading.readAt.toLocal())),
                ),
            ],
          );
        },
      ),
    );
  }
}
