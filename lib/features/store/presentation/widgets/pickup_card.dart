import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/widgets/section_card.dart';
import 'shipment_status_pill.dart';

/// Tarjeta de un envío para entrega en mostrador: lleva al POD al tocarla.
class PickupCard extends StatelessWidget {
  const PickupCard({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      onTap: () => context.push('/store/pickup/pod', extra: shipment),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.customerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pedido ${shipment.externalId}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (shipment.customerDocumentId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Doc: ${shipment.customerDocumentId}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                ShipmentStatusPill(shipment.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
