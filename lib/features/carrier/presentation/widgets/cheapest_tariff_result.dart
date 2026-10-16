import 'package:flutter/material.dart';

import '../../../../core/api/models/tariff.dart';
import '../../../../core/widgets/section_card.dart';
import 'corridor_format.dart';
import 'settlement_format.dart';

/// Resultado de la tarifa más barata encontrada para un corredor y tipo.
class CheapestTariffResult extends StatelessWidget {
  const CheapestTariffResult({super.key, required this.tariff});

  final Tariff tariff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Tarifa más barata',
      child: Column(
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
          Text(vehicleClassLabel(tariff.vehicleClass)),
          const SizedBox(height: 4),
          Text(
            'Vigente desde ${tariff.effectiveFrom.toLocal().toString().split(' ').first}',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
