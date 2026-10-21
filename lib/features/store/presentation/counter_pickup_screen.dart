import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/store_controllers.dart';
import 'widgets/pickup_card.dart';

/// Lista de envíos para entrega en mostrador (recojo en tienda). El cliente
/// retira y se toma la prueba de entrega en la siguiente pantalla.
class CounterPickupScreen extends ConsumerWidget {
  const CounterPickupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(storeShipmentsProvider);
    // Lista con datos: tarjetas perezosas (grilla en tablets). Cargando, vacío
    // o error ocupan el resto de la pantalla pero siguen siendo "scrolleables"
    // para que el gesto de refrescar funcione también ahí.
    final shipments = shipmentsAsync.hasError ? null : shipmentsAsync.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(storeShipmentsProvider),
        child: ResponsiveBody(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (shipments != null && shipments.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverAdaptiveCardRows(
                    itemCount: shipments.length,
                    itemBuilder: (context, i) =>
                        PickupCard(shipment: shipments[i]),
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncValueView<List<Shipment>>(
                    value: shipmentsAsync,
                    onRetry: () => ref.invalidate(storeShipmentsProvider),
                    data: (_) => const EmptyState(
                      icon: Icons.storefront,
                      title: 'Sin recojos',
                      message: 'No hay pedidos para recojo en tienda.',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
