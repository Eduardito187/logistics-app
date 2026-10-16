import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_badge.dart';
import 'controllers/store_controllers.dart';
import 'widgets/pickup_card.dart';

/// Lista de envíos para entrega en mostrador (recojo en tienda). El cliente
/// retira y se toma la prueba de entrega en la siguiente pantalla.
class CounterPickupScreen extends ConsumerWidget {
  const CounterPickupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega en mostrador'),
        actions: [
          SyncBadge(onTap: () => context.push('/sync')),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(storeShipmentsProvider),
        child: AsyncValueView<List<Shipment>>(
          value: shipmentsAsync,
          onRetry: () => ref.invalidate(storeShipmentsProvider),
          data: (shipments) {
            if (shipments.isEmpty) {
              return const EmptyState(
                icon: Icons.storefront,
                title: 'Sin recojos',
                message: 'No hay envíos para entregar en mostrador.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final shipment in shipments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PickupCard(shipment: shipment),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
