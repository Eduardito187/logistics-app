import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/store_controllers.dart';
import 'shipment_card.dart';

/// Sección con la lista de envíos que llegan al nodo seleccionado.
class ShipmentsSection extends ConsumerWidget {
  const ShipmentsSection({super.key, required this.node});

  final Node node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Envíos',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        AsyncValueView<List<Shipment>>(
          value: shipmentsAsync,
          onRetry: () => ref.invalidate(storeShipmentsProvider),
          data: (shipments) {
            if (shipments.isEmpty) {
              return const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin envíos',
                message: 'No hay envíos para recibir por ahora.',
              );
            }
            return Column(
              children: [
                for (final shipment in shipments)
                  ShipmentCard(shipment: shipment, node: node),
              ],
            );
          },
        ),
      ],
    );
  }
}
