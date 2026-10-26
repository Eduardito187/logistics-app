import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_loaded_units.dart';
import 'driver_vehicle_gate.dart';
import 'scan_mode.dart';
import 'scan_units_screen.dart';

/// Carga del camión: lista de envíos asignados al vehículo; al elegir uno se
/// escanean sus bultos para cargarlos (registro de carga offline).
class LoadScanScreen extends ConsumerWidget {
  const LoadScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Carga del camión',
      builder: (context, vehicleId) {
        final deliveries = ref.watch(vehicleDeliveriesProvider);
        final loaded = ref.watch(locallyLoadedUnitsProvider);
        return AsyncValueView<List<Delivery>>(
          value: deliveries,
          onRetry: () => ref.invalidate(vehicleDeliveriesProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory,
                title: 'Sin envíos',
                message: 'No hay envíos asignados a este vehículo.',
              );
            }
            return AdaptiveCardRows(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final delivery = list[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.inventory_2, size: 32),
                    title: Text('Envío ${delivery.shipmentId}'),
                    subtitle: Text(
                      '${effectiveScanCount(delivery, loaded[delivery.shipmentId])} escaneo(s)',
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
