import 'package:flutter/material.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import 'corridor_format.dart';
import 'settlement_format.dart';

/// Resultado de una asignación por volumen: vehículo sugerido y tarifa más
/// barata para esa clase en el corredor.
class AssignmentResult extends StatelessWidget {
  const AssignmentResult({super.key, required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tariff = assignment.tariff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.local_shipping,
                value: vehicleClassLabel(assignment.vehicleClass),
                label: 'Vehículo sugerido',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.inventory_2,
                value: '${assignment.volumeM3} m³',
                label: 'Volumen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Tarifa más barata',
          child: tariff == null
              ? Text(
                  'No hay tarifa registrada para esta clase en el corredor.',
                  style: TextStyle(color: theme.colorScheme.outline),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCents(tariff.priceCents, tariff.currency),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tariff.carrierName != null) Text(tariff.carrierName!),
                    Text('${tariff.corridorFrom} → ${tariff.corridorTo}'),
                    Text(corridorTypeLabel(tariff.corridorType)),
                  ],
                ),
        ),
      ],
    );
  }
}
