import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/adaptive_card_rows.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/store_shipments_notifier.dart';
import '../controllers/store_shipments_state.dart';
import 'load_more_footer.dart';
import 'shipment_card.dart';

/// Sección (sliver) con la lista de envíos que llegan al nodo seleccionado.
/// Va dentro de un `CustomScrollView`: las tarjetas se construyen a demanda y
/// el pie pide la página siguiente (el disparo por scroll lo pone la pantalla
/// con `LoadMoreOnScroll`).
class ShipmentsSection extends ConsumerWidget {
  const ShipmentsSection({super.key, required this.node});

  final Node node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsPagedProvider);
    final paged = shipmentsAsync.hasError ? null : shipmentsAsync.value;
    final shipments = paged?.shipments;
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
        if (shipments != null && shipments.isNotEmpty) ...[
          SliverAdaptiveCardRows(
            itemCount: shipments.length,
            itemBuilder: (context, i) =>
                ShipmentCard(shipment: shipments[i], node: node),
          ),
          if (paged!.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: LoadMoreFooter(
                  loading: paged.loadingMore,
                  failed: paged.moreFailed,
                  onLoadMore: () =>
                      ref.read(storeShipmentsPagedProvider.notifier).loadMore(),
                  label: 'Cargar más envíos',
                  loadingLabel: 'Cargando más envíos…',
                  failedLabel: 'No se pudieron cargar más envíos.',
                ),
              ),
            ),
        ] else
          SliverToBoxAdapter(
            child: AsyncValueView<StoreShipmentsState>(
              value: shipmentsAsync,
              onRetry: () => ref.invalidate(storeShipmentsPagedProvider),
              data: (_) => const EmptyState(
                icon: AppIcon.inbox,
                title: 'Sin envíos',
                message: 'No hay envíos para recibir por ahora.',
              ),
            ),
          ),
      ],
    );
  }
}
