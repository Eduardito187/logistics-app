import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_tile.dart';

/// Contadores de la recepción: recibidos/esperados, faltantes y, si hay,
/// sobrantes (bultos que no estaban en el manifiesto).
class ReceptionStats extends StatelessWidget {
  const ReceptionStats({
    super.key,
    required this.receivedExpected,
    required this.expectedCount,
    required this.pending,
    required this.surplusCount,
  });

  /// Recibidos que estaban en el manifiesto (los sobrantes no inflan "2/2").
  final int receivedExpected;
  final int expectedCount;
  final int pending;
  final int surplusCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '$receivedExpected/$expectedCount',
                label: 'Recibidos',
                icon: Icons.inventory_2,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '$pending',
                label: 'Faltan',
                icon: Icons.hourglass_bottom,
                color: pending == 0 ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
        if (surplusCount > 0) ...[
          const SizedBox(height: 12),
          StatTile(
            value: '$surplusCount',
            label: 'Sobrantes (no esperados)',
            icon: Icons.report_gmailerrorred,
            color: AppColors.danger,
          ),
        ],
      ],
    );
  }
}
