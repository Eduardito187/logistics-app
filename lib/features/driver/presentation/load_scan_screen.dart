import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_loaded_units.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_vehicle_gate.dart';
import 'scan_mode.dart';
import 'scan_units_screen.dart';

/// Carga del camión: lista de envíos asignados al vehículo; al elegir uno se
/// escanean sus productos para cargarlos (registro de carga offline).
class LoadScanScreen extends ConsumerWidget {
  const LoadScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Carga del camión',
      builder: (context, vehicleId) {
        final deliveries = ref.watch(vehicleDeliveriesProvider);
        final loaded = ref.watch(locallyLoadedUnitsProvider);
        // La hoja de ruta (ya cargada y compartida por toda la sección del
        // chofer: no es otra llamada) aporta lo que la lista de carga no trae:
        // cliente, nº de pedido y el estado EFECTIVO de cada parada.
        final route = ref.watch(driverRouteProvider).value;
        final settled = ref.watch(locallySettledStopsProvider);
        final stopByShipment = <String, DriverRouteStop>{
          for (final stop in route?.stops ?? const <DriverRouteStop>[])
            stop.shipmentId: stop,
        };
        return AsyncValueView<List<Delivery>>(
          value: deliveries,
          onRetry: () => ref.invalidate(vehicleDeliveriesProvider),
          data: (all) {
            if (all.isEmpty) {
              return const EmptyState(
                icon: AppIcon.receive,
                title: 'Sin envíos',
                message: 'No hay envíos asignados a este vehículo.',
              );
            }
            // Honestidad de datos: lo ya ENTREGADO (o fallido) no se "carga al
            // camión". Se excluye por el estado de la entrega y por el estado
            // efectivo de su parada (incluye lo resuelto en este teléfono).
            final list = [
              for (final delivery in all)
                if (!_alreadyResolved(
                  delivery,
                  stopByShipment[delivery.shipmentId],
                  settled,
                ))
                  delivery,
            ];
            if (list.isEmpty) {
              return const EmptyState(
                icon: AppIcon.success,
                title: 'Nada por cargar',
                message: 'Los envíos de este vehículo ya fueron entregados.',
              );
            }
            return AdaptiveCardRows(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final delivery = list[i];
                final stop = stopByShipment[delivery.shipmentId];
                // La entrega ya trae cliente y pedido; la hoja de ruta es el
                // respaldo (backend anterior).
                final customer = delivery.customerName ?? stop?.customerName;
                final order = delivery.orderReference ?? stop?.orderReference;
                final scans =
                    '${effectiveScanCount(delivery, loaded[delivery.shipmentId])} escaneo(s)';
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: const AnimatedAppIcon(AppIcon.receive, size: 32),
                    // Descriptivo: cliente y nº de pedido (de la hoja de ruta).
                    // Solo si el envío no está en la ruta cae al nº de orden en
                    // la lista (nunca el uuid).
                    title: Text(
                      customer ??
                          (order != null ? 'Pedido $order' : 'Envío ${i + 1}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer != null && order != null)
                          Text('Pedido $order'),
                        Text(scans),
                      ],
                    ),
                    trailing: StatusPill(
                      _label(delivery.status),
                      tone: _tone(delivery.status),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ScanUnitsScreen(
                            mode: ScanMode.load,
                            shipmentId: delivery.shipmentId,
                            title: 'Cargar envío',
                          ),
                        ),
                      );
                      // Al volver: conteos y estados del backend al día (la
                      // lista anterior sigue visible mientras se refresca; lo
                      // escaneado sin señal ya se suma desde la sesión).
                      if (!context.mounted) return;
                      ref.invalidate(vehicleDeliveriesProvider);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// `true` si el envío ya no tiene nada que cargar: la entrega está cerrada
/// (entregada/fallida) o su parada ya se resolvió (backend o este teléfono).
bool _alreadyResolved(
  Delivery delivery,
  DriverRouteStop? stop,
  Map<String, DriverRouteStopStatus> settled,
) {
  if (delivery.status == DeliveryStatus.delivered ||
      delivery.status == DeliveryStatus.failed) {
    return true;
  }
  return stop != null &&
      effectiveStopStatus(stop, settled) != DriverRouteStopStatus.pending;
}

String _label(DeliveryStatus status) => switch (status) {
  DeliveryStatus.pending => 'Pendiente',
  DeliveryStatus.prepared => 'Preparado',
  DeliveryStatus.loaded => 'Cargado',
  DeliveryStatus.inTransit => 'En tránsito',
  DeliveryStatus.delivered => 'Entregado',
  DeliveryStatus.failed => 'Fallido',
  _ => 'Envío',
};

PillTone _tone(DeliveryStatus status) => switch (status) {
  DeliveryStatus.delivered => PillTone.success,
  DeliveryStatus.failed => PillTone.danger,
  DeliveryStatus.inTransit || DeliveryStatus.loaded => PillTone.info,
  _ => PillTone.neutral,
};
