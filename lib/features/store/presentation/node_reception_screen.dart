import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/selected_store_node_notifier.dart';
import 'controllers/store_controllers.dart';
import 'widgets/shipments_section.dart';
import 'widgets/store_selector.dart';

/// Entrada del flujo de recepción contra manifiesto: la tienda es la del
/// usuario (fija) y se elige el envío que está llegando para abrir/continuar
/// su recepción.
class NodeReceptionScreen extends ConsumerWidget {
  const NodeReceptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedStoreNodeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recepción de mercadería')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(storeShipmentsProvider),
        child: ResponsiveBody(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: StoreSelector()),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: selected == null
                    ? const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.storefront,
                          title: 'Sin tienda asignada',
                          message:
                              'Tu usuario no tiene una tienda asignada. '
                              'Contactá a tu supervisor.',
                        ),
                      )
                    : ShipmentsSection(node: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
