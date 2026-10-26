import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../driver_common.dart';

/// Rejilla de costos del vehículo (TCO, costo/km, combustible, etc.).
class CostGrid extends StatelessWidget {
  const CostGrid(this.summary, {super.key});

  final VehicleCostSummary summary;

  /// Ancho mínimo de un mosaico: 2 columnas en un teléfono típico, 1 en uno
  /// chico, hasta 3 en tablets.
  static const double _minTileWidth = 140;
  static const double _spacing = 12;

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
    // Sin proporción fija (un GridView 1.5:1 se desbordaba en 320 dp con letra
    // 1.3x): columnas según el ancho disponible y alto según el contenido.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minTileWidth).floor().clamp(
          1,
          3,
        );
        final tileWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}
