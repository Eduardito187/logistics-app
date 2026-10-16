import 'package:flutter/material.dart';

import '../../../../core/api/models/planned_stop.dart';

/// Fila de parada (solo lectura) dentro de la secuencia de un plan.
class StopTile extends StatelessWidget {
  const StopTile({super.key, required this.position, required this.stop});

  final int position;
  final PlannedStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      'Carga #${stop.loadOrder}',
      if (stop.lane != null) 'Carril ${stop.lane}',
      if (stop.etaMinutes != null) '${stop.etaMinutes} min',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$position',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envío ${stop.shipmentId}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
