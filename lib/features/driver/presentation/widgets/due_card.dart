import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/due_maintenance_item.dart';
import '../fleet_ops_common.dart';
import 'urgency_pill.dart';

/// Tarjeta de un mantenimiento por vencer: servicio, vehículo, vencimiento y
/// urgencia.
class DueCard extends StatelessWidget {
  const DueCard({super.key, required this.item});

  final DueMaintenanceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('es');
    final dateFormat = DateFormat('d MMM y', 'es');

    final details = <String>[];
    if (item.nextDueAt != null) {
      details.add('Vence: ${dateFormat.format(item.nextDueAt!.toLocal())}');
    }
    if (item.remainingDays != null) {
      details.add(_remainingDaysLabel(item.remainingDays!));
    }
    if (item.nextDueKm != null) {
      details.add('A los ${numberFormat.format(item.nextDueKm)} km');
    }
    if (item.remainingKm != null) {
      details.add(_remainingKmLabel(item.remainingKm!, numberFormat));
    }
    if (item.currentKm != null) {
      details.add('Actual: ${numberFormat.format(item.currentKm)} km');
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceKindLabel(item.serviceKind),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              UrgencyPill(urgency: item.urgency),
            ],
          ),
          if (item.plate != null || item.vehicleId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Vehículo: ${item.plate ?? item.vehicleId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in details)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line),
              ),
          ],
        ],
      ),
    );
  }

  String _remainingDaysLabel(int days) {
    if (days < 0) return 'Vencido hace ${-days} días';
    if (days == 0) return 'Vence hoy';
    return 'Faltan $days días';
  }

  String _remainingKmLabel(int km, NumberFormat format) {
    if (km < 0) return 'Pasado por ${format.format(-km)} km';
    return 'Faltan ${format.format(km)} km';
  }
}
