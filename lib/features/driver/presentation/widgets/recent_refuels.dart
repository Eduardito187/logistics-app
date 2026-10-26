import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/fleet_ops_controllers.dart';
import '../driver_common.dart';
import '../fleet_ops_common.dart';

/// Formato de fecha creado una vez (no en cada build).
final DateFormat _dateFormat = DateFormat('d MMM, HH:mm', 'es');

/// Cargas de combustible recientes del vehículo.
class RecentRefuels extends ConsumerWidget {
  const RecentRefuels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refuels = ref.watch(vehicleRefuelsProvider);
    return SectionCard(
      title: 'Cargas recientes',
      child: AsyncValueView<List<Refuel>>(
        value: refuels,
        onRetry: () => ref.invalidate(vehicleRefuelsProvider),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.local_gas_station,
              title: 'Sin cargas registradas',
              message: 'Las cargas que registres aparecerán aquí.',
            );
          }
          return Column(
            children: [
              for (final refuel in items.take(10))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.local_gas_station,
                    color: AppColors.warning,
                  ),
                  title: Text(
                    '${refuel.liters.toStringAsFixed(2)} L · '
                    '${formatMoneyCents(refuel.totalCostCents, refuel.currency)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${fuelTypeLabel(refuel.fuelType)} · '
                    '${_dateFormat.format(refuel.refueledAt.toLocal())}'
                    '${refuel.odometerKm != null ? ' · ${refuel.odometerKm} km' : ''}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
