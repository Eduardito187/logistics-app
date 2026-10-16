import 'package:flutter/material.dart';

import '../../../../core/api/models/tariff.dart';
import '../../../../core/widgets/section_card.dart';
import 'corridor_format.dart';
import 'settlement_format.dart';

/// Resultado de la consulta de tarifa vigente por corredor y clase de vehículo.
class TariffResult extends StatelessWidget {
  const TariffResult({super.key, required this.tariff});

  final Tariff tariff;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Tarifa vigente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatCents(tariff.priceCents, tariff.currency),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('${tariff.corridorFrom} → ${tariff.corridorTo}'),
          Text(corridorTypeLabel(tariff.corridorType)),
          Text(vehicleClassLabel(tariff.vehicleClass)),
          const SizedBox(height: 4),
          Text(
            'Vigente desde ${tariff.effectiveFrom.toLocal().toString().split(' ').first}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
