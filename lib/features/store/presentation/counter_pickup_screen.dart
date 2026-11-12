import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/store_shipments_notifier.dart';
import 'controllers/store_shipments_state.dart';
import 'widgets/load_more_footer.dart';
import 'widgets/load_more_on_scroll.dart';
import 'widgets/pickup_card.dart';

/// Lista de envíos para entrega en mostrador (recojo en tienda). El cliente
/// retira y se toma la prueba de entrega en la siguiente pantalla.
class CounterPickupScreen extends ConsumerWidget {
  const CounterPickupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsPagedProvider);
    // Lista con datos: tarjetas perezosas (grilla en tablets). Cargando, vacío
    // o error ocupan el resto de la pantalla pero siguen siendo "scrolleables"
    // para que el gesto de refrescar funcione también ahí.
    final paged = shipmentsAsync.hasError ? null : shipmentsAsync.value;
    final shipments = paged?.shipments;
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: RefreshIndicator(
        // Refrescar vuelve a la página 1 (lo que espera el gesto).
        onRefresh: () async => ref.invalidate(storeShipmentsPagedProvider),
        child: LoadMoreOnScroll(
          onLoadMore: () =>
              ref.read(storeShipmentsPagedProvider.notifier).loadMore(),
          child: ResponsiveBody(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (shipments != null && shipments.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverAdaptiveCardRows(
                          itemCount: shipments.length,
                          itemBuilder: (context, i) =>
                              PickupCard(shipment: shipments[i]),
                        ),
                        // Scroll infinito: al acercarse al final se pide la
                        // página siguiente y el pie muestra el progreso.
                        if (paged!.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: LoadMoreFooter(
                                loading: paged.loadingMore,
                                failed: paged.moreFailed,
                                onLoadMore: () => ref
                                    .read(storeShipmentsPagedProvider.notifier)
                                    .loadMore(),
                                label: 'Cargar más recojos',
                                loadingLabel: 'Cargando más recojos…',
                                failedLabel:
                                    'No se pudieron cargar más recojos.',
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AsyncValueView<StoreShipmentsState>(
                      value: shipmentsAsync,
                      onRetry: () =>
                          ref.invalidate(storeShipmentsPagedProvider),
                      data: (_) => const EmptyState(
                        icon: AppIcon.pickupStore,
                        title: 'Sin recojos',
                        message: 'No hay pedidos para recojo en tienda.',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
