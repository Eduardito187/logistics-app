import 'package:flutter/material.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../supervisor_labels.dart';

/// Tarjeta resumen de un plan del día: camión, estado, paradas y ETA final.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final stops = plan.stops;
    final lastEta = planFinalEta(stops);

    return SectionCard(
      title: 'Camión ${plan.vehicleId}',
      trailing: StatusPill(
        planStatusLabel(plan.status),
        tone: planStatusTone(plan.status),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop, size: 18),
              const SizedBox(width: 6),
              Text('${stops.length} paradas'),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 6),
              Text(
                lastEta == null
                    ? 'ETA final: —'
                    : 'ETA final: ${formatHour(lastEta)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
