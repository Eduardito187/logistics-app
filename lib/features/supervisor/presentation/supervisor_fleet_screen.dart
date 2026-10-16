import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/vehicle_live.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/fleet_map.dart';

/// Flota en vivo: mapa OSM con la última posición conocida de cada camión.
class SupervisorFleetScreen extends ConsumerWidget {
  const SupervisorFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet = ref.watch(fleetLiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flota en vivo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(fleetLiveProvider),
          ),
        ],
      ),
      body: AsyncValueView<List<VehicleLive>>(
        value: fleet,
        onRetry: () => ref.invalidate(fleetLiveProvider),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              title: 'Sin camiones en vivo',
              message: 'No hay posiciones de telemetría por ahora.',
            );
          }
          return FleetMap(vehicles: vehicles);
        },
      ),
    );
  }
}
