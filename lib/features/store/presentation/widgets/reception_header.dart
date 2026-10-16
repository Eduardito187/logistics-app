import 'package:flutter/material.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/widgets/section_card.dart';

/// Cabecera de la recepción: cliente, pedido y nodo que recibe.
class ReceptionHeader extends StatelessWidget {
  const ReceptionHeader({
    super.key,
    required this.shipment,
    required this.node,
  });

  final Shipment shipment;
  final Node node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipment.customerName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido ${shipment.externalId}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Nodo: ${node.name} · ${node.code}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
