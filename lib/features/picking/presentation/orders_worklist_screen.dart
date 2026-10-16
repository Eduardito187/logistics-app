import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_badge.dart';
import 'controllers/orders_worklist_controller.dart';
import 'widgets/order_card.dart';

/// Worklist del preparador/andén: lista de pedidos pendientes de preparar y
/// cargar al camión. Reemplaza el ingreso manual del número de pedido como
/// acción principal. Cada tarjeta abre la pantalla de preparación del pedido.
class OrdersWorklistScreen extends ConsumerWidget {
  const OrdersWorklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersToPrepareProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos por preparar'),
        actions: [
          IconButton(
            tooltip: 'Ingresar pedido manualmente',
            icon: const Icon(Icons.keyboard),
            onPressed: () => context.push('/picking/prepare'),
          ),
          SyncBadge(onTap: () => context.push('/sync')),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersToPrepareProvider),
        child: AsyncValueView<List<Shipment>>(
          value: ordersAsync,
          onRetry: () => ref.invalidate(ordersToPrepareProvider),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 96),
                  EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No hay pedidos por preparar',
                    message:
                        'Cuando lleguen pedidos para armar y cargar al camión '
                        'aparecerán acá. Deslizá hacia abajo para actualizar.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  OrderCard(shipment: orders[index]),
            );
          },
        ),
      ),
    );
  }
}
