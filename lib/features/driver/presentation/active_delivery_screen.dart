import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/export.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/active_delivery/delivery_actions_bar.dart';
import 'widgets/active_delivery/delivery_help_sheet.dart';
import 'widgets/active_delivery/delivery_map.dart';
import 'widgets/active_delivery/delivery_sheet.dart';
import 'widgets/active_delivery/delivery_status_card.dart';
import 'widgets/active_delivery/map_round_button.dart';

export 'controllers/locally_settled_stops.dart' show currentStopOf;

/// Entrega en curso: el mapa ocupa la pantalla; arriba el estado (parada N de
/// M, hora estimada, progreso), abajo una hoja deslizable con los datos de la
/// entrega (cliente, teléfono, dirección) y el pedido (productos con SKU), y al
/// pie los botones del paso que corresponde (escanear bultos, entregar con foto,
/// no se pudo entregar). "Ayuda" reúne llamar, navegar y reportar problemas.
class ActiveDeliveryScreen extends ConsumerWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Entrega en curso',
      immersive: true,
      builder: (context, vehicleId) {
        final route = ref.watch(driverRouteProvider);
        // Lo resuelto en este teléfono (POD/fallida encolados sin señal) hace
        // avanzar la entrega sin esperar a que el backend se entere.
        final settled = ref.watch(locallySettledStopsProvider);
        return AsyncValueView<DriverRoute>(
          value: route,
          onRetry: () => ref.invalidate(driverRouteProvider),
          data: (data) {
            final stop = currentStopOf(data, settled);
            if (stop == null) return _RouteFinished(route: data);
            return _ActiveDelivery(route: data, stop: stop);
          },
        );
      },
    );
  }
}

class _ActiveDelivery extends ConsumerWidget {
  const _ActiveDelivery({required this.route, required this.stop});

  final DriverRoute route;
  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Esta pantalla NO mira el GPS: solo el mapa (camión) y la tarjeta de
    // estado (lo que falta) se reconstruyen con cada fix; la hoja, los botones
    // y el pie quedan quietos.
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: DeliveryMap(route: route, stop: stop),
              ),
              Positioned(
                top: topInset + 8,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        MapRoundButton(
                          tooltip: 'Cerrar',
                          icon: Icons.close,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        MapPillButton(
                          icon: Icons.support_agent,
                          label: 'Ayuda',
                          onPressed: () =>
                              showDeliveryHelpSheet(context, ref, stop: stop),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RepaintBoundary(
                      child: _LiveStatusCard(route: route, stop: stop),
                    ),
                  ],
                ),
              ),
              DeliverySheet(stop: stop),
            ],
          ),
        ),
        DeliveryActionsBar(stop: stop),
      ],
    );
  }
}

/// Tarjeta de estado con lo que falta en vivo: es lo único de la pantalla que
/// se reconstruye con cada posición del camión.
class _LiveStatusCard extends ConsumerWidget {
  const _LiveStatusCard({required this.route, required this.stop});

  final DriverRoute route;
  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fix = ref.watch(deliveryDriverFixProvider).value;
    return DeliveryStatusCard(
      route: route,
      stop: stop,
      remaining: remainingToStop(route, stop, fix),
    );
  }
}

/// Sin paradas pendientes: ruta del día terminada.
class _RouteFinished extends StatelessWidget {
  const _RouteFinished({required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MapRoundButton(
                tooltip: 'Cerrar',
                icon: Icons.close,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.task_alt,
              title: route.stops.isEmpty
                  ? 'Sin entregas asignadas'
                  : 'Ruta completada',
              message: route.stops.isEmpty
                  ? 'Todavía no tenés paradas para hoy.'
                  : 'Atendiste las ${route.totalStops} paradas del día.',
              action: OutlinedButton.icon(
                onPressed: () => context.push('/driver/route'),
                icon: const Icon(Icons.map),
                label: const Text('Ver ruta del día'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
