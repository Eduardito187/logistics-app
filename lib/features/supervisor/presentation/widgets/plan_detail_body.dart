import 'package:flutter/material.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/status_pill.dart';
import '../supervisor_labels.dart';
import 'detail_row.dart';
import 'eta_section.dart';
import 'stop_tile.dart';

/// Cuerpo del detalle (solo lectura) de un plan: cabecera, métricas, ETA y la
/// secuencia de paradas.
class PlanDetailBody extends StatelessWidget {
  const PlanDetailBody({super.key, required this.plan, required this.planId});

  final Plan plan;
  final String planId;

  @override
  Widget build(BuildContext context) {
    final stops = [...plan.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final finalEta = planFinalEta(stops);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Camión ${plan.vehicleId}',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusPill(
                    planStatusLabel(plan.status),
                    tone: planStatusTone(plan.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DetailRow(label: 'Fecha', value: formatDay(plan.planDate)),
              DetailRow(label: 'Plan', value: plan.id),
              if (plan.routeGeometry != null)
                const DetailRow(label: 'Ruta', value: 'Trazado disponible'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '${stops.length}',
                label: 'Paradas',
                icon: Icons.pin_drop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: finalEta == null ? '—' : formatHour(finalEta),
                label: 'ETA final',
                icon: Icons.schedule,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EtaSection(planId: planId),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Secuencia de paradas',
          child: stops.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('El plan todavía no tiene paradas.'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < stops.length; i++)
                      StopTile(position: i + 1, stop: stops[i]),
                  ],
                ),
        ),
      ],
    );
  }
}
