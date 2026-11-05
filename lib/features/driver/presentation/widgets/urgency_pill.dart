import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../../../core/icons/icons.dart';
import '../../domain/entities/due_maintenance_urgency.dart';

/// Chip de urgencia de un mantenimiento por vencer.
class UrgencyPill extends StatelessWidget {
  const UrgencyPill({super.key, required this.urgency});

  final DueMaintenanceUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (urgency) {
      DueMaintenanceUrgency.overdue => (
        'Vencido',
        PillTone.danger,
        AppIcon.error,
      ),
      DueMaintenanceUrgency.dueSoon => (
        'Por vencer',
        PillTone.warning,
        AppIcon.pending,
      ),
      DueMaintenanceUrgency.scheduled => (
        'Programado',
        PillTone.info,
        AppIcon.myDay,
      ),
    };
    return StatusPill(label, tone: tone, icon: icon);
  }
}
