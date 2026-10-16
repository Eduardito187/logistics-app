import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/layout/adaptive_card_rows.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/store_controllers.dart';
import 'shipment_card.dart';

/// Sección (sliver) con la lista de envíos que llegan al nodo seleccionado.
/// Va dentro de un `CustomScrollView`: las tarjetas se construyen a demanda.
class ShipmentsSection extends ConsumerWidget {
  const ShipmentsSection({super.key, required this.node});

  final Node node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsProvider);
    final shipments = shipmentsAsync.hasError ? null : shipmentsAsync.value;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Envíos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (shipments != null && shipments.isNotEmpty)
          SliverAdaptiveCardRows(
            itemCount: shipments.length,
            itemBuilder: (context, i) =>
                ShipmentCard(shipment: shipments[i], node: node),
          )
        else
          SliverToBoxAdapter(
            child: AsyncValueView<List<Shipment>>(
              value: shipmentsAsync,
              onRetry: () => ref.invalidate(storeShipmentsProvider),
              data: (_) => const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin envíos',
                message: 'No hay envíos para recibir por ahora.',
              ),
            ),
          ),
      ],
    );
  }
}
