import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/widgets/section_card.dart';
import 'shipment_status_pill.dart';

/// Tarjeta de un pedido a preparar: nº de pedido, cliente, cantidad de paquetes
/// y estado. Al tocarla abre la preparación reutilizando la navegación actual.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packageCount = shipment.lines.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        onTap: () => context.push('/picking/order/${shipment.externalId}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido ${shipment.externalId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shipment.customerName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    packageCount == 1 ? '1 paquete' : '$packageCount paquetes',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ShipmentStatusPill(shipment.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
