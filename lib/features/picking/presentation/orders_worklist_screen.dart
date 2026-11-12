import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/orders_worklist_controller.dart';
import 'widgets/order_card.dart';

/// Worklist del preparador/andén: lista de pedidos pendientes de preparar y
/// cargar al camión. Reemplaza el ingreso manual del número de pedido como
/// acción principal. Cada tarjeta abre la pantalla de preparación del pedido.
///
/// Carga incremental (scroll infinito): la colección se pagina por cursor y se
/// pide la tanda siguiente al acercarse al final. Antes se traía solo la
/// primera página y el resto se perdía en silencio.
class OrdersWorklistScreen extends ConsumerStatefulWidget {
  const OrdersWorklistScreen({super.key});

  @override
  ConsumerState<OrdersWorklistScreen> createState() =>
      _OrdersWorklistScreenState();
}

class _OrdersWorklistScreenState extends ConsumerState<OrdersWorklistScreen> {
  final _controller = ScrollController();

  /// Distancia al final (en px) a la que se empieza a traer la tanda siguiente,
  /// para que al usuario no le aparezca el spinner si puede evitarse.
  static const double _loadMoreThreshold = 600;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(ordersWorklistProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final worklistAsync = ref.watch(ordersWorklistProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos por preparar'),
        actions: [
          IconButton(
            tooltip: 'Ingresar pedido manualmente',
            icon: const AnimatedAppIcon(AppIcon.keyboard),
            onPressed: () => context.push('/picking/prepare'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersWorklistProvider),
        child: AsyncValueView<OrdersWorklistState>(
          value: worklistAsync,
          onRetry: () => ref.invalidate(ordersWorklistProvider),
          data: (state) {
            final orders = state.orders;
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 96),
                  EmptyState(
                    icon: AppIcon.receive,
                    title: 'No hay pedidos por preparar',
                    message:
                        'Cuando lleguen pedidos para armar y cargar al camión '
                        'aparecerán acá. Deslizá hacia abajo para actualizar.',
                  ),
                ],
              );
            }
            // Perezosa y en columnas: 1 en teléfono, 2–3 en tablet. OrderCard
            // ya trae su margen inferior, por eso las filas van sin separador.
            return CustomScrollView(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverAdaptiveCardRows(
                    itemCount: orders.length,
                    spacing: 0,
                    itemBuilder: (context, index) =>
                        OrderCard(shipment: orders[index]),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    navScrollBottomPadding(context),
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _LoadMoreFooter(
                      loading: state.loadingMore,
                      hasMore: state.hasMore,
                      total: orders.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pie de la lista: indicador mientras se trae la tanda siguiente, o el total
/// cuando ya se trajeron todos.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.loading,
    required this.hasMore,
    required this.total,
  });

  final bool loading;
  final bool hasMore;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
        ),
      );
    }
    if (hasMore) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          total == 1 ? '1 pedido' : '$total pedidos',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
