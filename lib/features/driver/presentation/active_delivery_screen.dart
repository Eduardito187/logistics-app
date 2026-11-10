import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/navigation/app_nav.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/active_delivery/delivery_actions_bar.dart';
import 'widgets/active_delivery/delivery_help_sheet.dart';
import 'widgets/active_delivery/delivery_map.dart';
import 'widgets/active_delivery/delivery_status_card.dart';
import 'widgets/active_delivery/map_round_button.dart';

export 'controllers/locally_settled_stops.dart' show currentStopOf;

/// Cierra la entrega: si se abrió EMPUJADA desde otra sección, vuelve atrás; si
/// es la pestaña central del shell (no hay nada que cerrar), va al Inicio. Así
/// la "X" SIEMPRE está y SIEMPRE hace algo (antes a veces quedaba muerta o no
/// aparecía, y confundía).
void _closeOrHome(BuildContext context, WidgetRef ref) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    ref.read(homeTabProvider.notifier).set(0);
  }
}

/// Entrega en curso: el MAPA ocupa casi toda la pantalla. Arriba, la "X" (izq)
/// y "Ayuda" (der) y el estado (parada N de M, hora estimada, progreso). Al
/// pie, una barra compacta con el cliente + "Ver pedido" (abre los datos y el
/// pedido en un modal BAJO DEMANDA, no una hoja siempre abierta que tapaba el
/// mapa) y los botones del paso: entregar con foto, escanear bultos, no se pudo.
/// "Ayuda" reúne llamar, navegar y reportar problemas.
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
    // Importante: este árbol NO observa la posición en vivo. El fix del GPS
    // llega cada segundo y sólo debe reconstruir la tarjeta de estado (y el
    // mapa, que observa el fix por su cuenta); si lo observáramos acá se
    // reconstruirían también la hoja deslizable y la barra de acciones en cada
    // emisión, saturando la CPU.
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
                        // "X" SIEMPRE visible (cierra o vuelve al Inicio).
                        MapRoundButton(
                          tooltip: 'Cerrar',
                          icon: AppIcon.close,
                          onPressed: () => _closeOrHome(context, ref),
                        ),
                        const Spacer(),
                        // "Ayuda" a la DERECHA (llamar, navegar, reportar).
                        MapPillButton(
                          icon: AppIcon.support,
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
            ],
          ),
        ),
        DeliveryActionsBar(stop: stop),
      ],
    );
  }
}

/// Tarjeta de estado que sí observa la posición en vivo: es el único widget que
/// se reconstruye con cada fix del GPS para recalcular lo que falta a la parada.
/// Aislarla evita reconstruir el mapa padre, la hoja y la barra de acciones.
class _LiveStatusCard extends ConsumerWidget {
  const _LiveStatusCard({required this.route, required this.stop});

  final DriverRoute route;
  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fix = ref.watch(deliveryDriverFixProvider).value;
    final remaining = remainingToStop(route, stop, fix);
    return DeliveryStatusCard(route: route, stop: stop, remaining: remaining);
  }
}

/// Sin paradas pendientes: ruta del día terminada.
class _RouteFinished extends ConsumerWidget {
  const _RouteFinished({required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
          // "X" SIEMPRE visible, consistente con la entrega en curso.
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MapRoundButton(
                tooltip: 'Cerrar',
                icon: AppIcon.close,
                onPressed: () => _closeOrHome(context, ref),
              ),
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: AppIcon.deliverScan,
              title: route.stops.isEmpty
                  ? 'Sin entregas asignadas'
                  : 'Ruta completada',
              message: route.stops.isEmpty
                  ? 'Todavía no tenés paradas para hoy.'
                  : 'Atendiste las ${route.totalStops} paradas del día.',
              action: OutlinedButton.icon(
                onPressed: () => context.push('/driver/route'),
                icon: const AnimatedAppIcon(AppIcon.map),
                label: const Text('Ver ruta del día'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
