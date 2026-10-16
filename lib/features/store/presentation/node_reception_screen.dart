import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_badge.dart';
import 'controllers/selected_store_node_notifier.dart';
import 'controllers/store_controllers.dart';
import 'widgets/shipments_section.dart';
import 'widgets/store_selector.dart';

/// Entrada del flujo de recepción contra manifiesto: el personal elige su tienda
/// (nodo destino) y luego el envío que está llegando para abrir/continuar su
/// recepción.
class NodeReceptionScreen extends ConsumerWidget {
  const NodeReceptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedStoreNodeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepción de mercadería'),
        actions: [
          SyncBadge(onTap: () => context.push('/sync')),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(storeNodesProvider)
            ..invalidate(storeShipmentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const StoreSelector(),
            const SizedBox(height: 16),
            if (selected == null)
              const EmptyState(
                icon: Icons.storefront,
                title: 'Elige tu tienda',
                message:
                    'Selecciona el nodo donde estás recibiendo para ver los '
                    'envíos que llegan.',
              )
            else
              ShipmentsSection(node: selected),
          ],
        ),
      ),
    );
  }
}
