import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../supervisor_labels.dart';
import '../vehicle_label.dart';

/// Tarjeta resumen de un plan del día: camión, estado, paradas y ETA final.
/// Al tocarla abre el detalle del plan, pasándole el plan de la lista para que
/// se vea al instante.
class PlanCard extends ConsumerWidget {
  const PlanCard({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stops = plan.stops;
    final lastEta = planFinalEta(stops);

    return SectionCard(
      onTap: () => context.push('/supervisor/plans/${plan.id}', extra: plan),
      title: vehicleLabel(ref, plan.vehicleId),
      trailing: StatusPill(
        planStatusLabel(plan.status),
        tone: planStatusTone(plan.status),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap: en un teléfono chico con letra grande "paradas" y "ETA
          // final" no entran en una fila y la segunda baja en vez de desbordar.
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _IconText(icon: Icons.pin_drop, text: '${stops.length} paradas'),
              _IconText(
                icon: Icons.schedule,
                text: lastEta == null
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

/// Ícono chico + texto, como una sola pieza que no se parte entre filas.
class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(text)),
      ],
    );
  }
}
