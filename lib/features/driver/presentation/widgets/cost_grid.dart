import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../driver_common.dart';

/// Rejilla de costos del vehículo (TCO, costo/km, combustible, etc.).
class CostGrid extends StatelessWidget {
  const CostGrid(this.summary, {super.key});

  final VehicleCostSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = summary.currency;
    final tiles = <Widget>[
      StatTile(
        value: formatMoneyCents(summary.totalCents, currency),
        label: 'Costo total',
        icon: Icons.payments,
        color: AppColors.brand,
      ),
      StatTile(
        value: summary.costPerKmCents == null
            ? '—'
            : formatMoneyCents(summary.costPerKmCents!, currency),
        label: 'Costo por km',
        icon: Icons.speed,
        color: AppColors.info,
      ),
      StatTile(
        value: formatMoneyCents(summary.fuelCents, currency),
        label: 'Combustible',
        icon: Icons.local_gas_station,
        color: AppColors.warning,
      ),
      StatTile(
        value: formatMoneyCents(summary.maintenanceCents, currency),
        label: 'Mantenimiento',
        icon: Icons.build,
        color: AppColors.success,
      ),
      StatTile(
        value: formatMoneyCents(summary.expensesCents, currency),
        label: 'Otros gastos',
        icon: Icons.receipt_long,
      ),
      StatTile(
        value: '${summary.kilometers} km',
        label: 'Recorrido',
        icon: Icons.route,
        color: AppColors.brandDark,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: tiles,
    );
  }
}
