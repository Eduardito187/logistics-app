import 'package:flutter/material.dart';

import '../../../../core/api/models/stop_eta.dart';
import '../supervisor_labels.dart';

/// Fila de ETA por parada: secuencia, envío y hora estimada.
class EtaRow extends StatelessWidget {
  const EtaRow({super.key, required this.stop});

  final StopEta stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              '${stop.sequence}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Envío ${stop.shipmentId}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            stop.etaAt == null ? '—' : formatHour(stop.etaAt!),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
