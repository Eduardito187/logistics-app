import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../driver_common.dart';

/// Cabecera de solo lectura con la asignación del día: vehículo, chofer,
/// ayudantes y turno. No permite cambiar nada (la asigna el supervisor).
class AssignmentHeader extends StatelessWidget {
  const AssignmentHeader({super.key, required this.crew});

  final MyCrew crew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plate = crew.vehicle.plate ?? crew.vehicle.id;
    final driverName = crew.driver.name ?? 'Chofer asignado';
    final helpers = crew.helpers
        .map((h) => h.name)
        .whereType<String>()
        .toList(growable: false);
    final shift = crew.shift;

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.local_shipping, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('Chofer: $driverName', style: theme.textTheme.bodySmall),
                  if (helpers.isNotEmpty)
                    Text(
                      'Ayudantes: ${helpers.join(', ')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (shift != null)
                    Text(
                      'Turno: ${formatTime(shift.startsAt)}'
                      ' - ${formatTime(shift.endsAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
