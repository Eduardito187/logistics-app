import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_type.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/widgets/section_card.dart';
import 'shipment_status_pill.dart';

/// Tarjeta de un envío en la lista de recepción: abre el detalle de recepción
/// para el envío en el nodo destino.
class ShipmentCard extends StatelessWidget {
  const ShipmentCard({super.key, required this.shipment, required this.node});

  final Shipment shipment;
  final Node node;

  @override
  Widget build(BuildContext context) {
    final destination = node.type == NodeType.store ? 'tienda' : 'nodo';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        onTap: () => context.push(
          '/store/reception/detail',
          extra: (shipment: shipment, node: node),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.customerName,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pedido ${shipment.externalId}  ·  ${shipment.lines.length} ítems',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recibir en $destination · ${node.name}',
                    style: Theme.of(context).textTheme.bodySmall,
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
