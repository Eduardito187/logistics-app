import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../domain/dashboard_metrics.dart';
import '../supervisor_labels.dart';

/// Cuerpo del tablero: tarjeta de resumen y grilla de métricas del día.
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key, required this.metrics, required this.date});

  final DashboardMetrics metrics;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final rate = metrics.fulfillmentRate;
    final rateLabel = rate == null ? '—' : '${(rate * 100).round()}%';

    final tiles = <Widget>[
      StatTile(
        value: '${metrics.delivered}',
        label: 'Entregadas',
        icon: Icons.check_circle,
        color: AppColors.success,
      ),
      StatTile(
        value: '${metrics.inExecution}',
        label: 'En ruta',
        icon: Icons.local_shipping,
        color: AppColors.info,
      ),
      StatTile(
        value: '${metrics.failed}',
        label: 'Fallidas',
        icon: Icons.cancel,
        color: AppColors.danger,
      ),
      StatTile(
        value: rateLabel,
        label: 'Cumplimiento',
        icon: Icons.verified,
        color: AppColors.brand,
      ),
      StatTile(
        value: '${metrics.pending}',
        label: 'Por salir',
        icon: Icons.inventory_2,
        color: AppColors.warning,
      ),
      StatTile(
        value: '${metrics.activePlans}',
        label: 'Rutas en curso',
        icon: Icons.alt_route,
        color: AppColors.brand,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Resumen de ${formatDay(date)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${metrics.total} envíos del día en total'),
              const SizedBox(height: 4),
              Text('${metrics.openAlerts} alertas sin reconocer'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: tiles,
        ),
      ],
    );
  }
}
