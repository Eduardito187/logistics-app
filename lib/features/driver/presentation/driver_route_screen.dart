import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/usecases/assemble_daily_route.dart';
import 'controllers/driver_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/route_list.dart';
import 'widgets/route_map.dart';
import 'widgets/route_summary.dart';

/// Ruta del día: paradas del vehículo en mapa (OSM) y como lista.
class DriverRouteScreen extends ConsumerStatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  ConsumerState<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends ConsumerState<DriverRouteScreen> {
  bool _showMap = true;
  bool _assembling = false;

  @override
  Widget build(BuildContext context) {
    return DriverVehicleGate(
      title: 'Mi ruta de hoy',
      actions: [
        IconButton(
          tooltip: 'Armar ruta del día',
          icon: AnimatedAppIcon(
            AppIcon.checklist,
            state: _assembling ? AppIconState.loading : AppIconState.idle,
          ),
          onPressed: _assembling ? null : _assembleDailyRoute,
        ),
        IconButton(
          tooltip: _showMap ? 'Ver lista' : 'Ver mapa',
          icon: AnimatedAppIcon(_showMap ? AppIcon.orders : AppIcon.map),
          onPressed: () => setState(() => _showMap = !_showMap),
        ),
      ],
      builder: (context, vehicleId) {
        final route = ref.watch(driverRouteProvider);
        return AsyncValueView<DriverRoute>(
          value: route,
          onRetry: () => ref.invalidate(driverRouteProvider),
          data: (data) {
            if (data.stops.isEmpty) {
              return EmptyState(
                icon: AppIcon.route,
                title: 'Sin paradas',
                message: 'Esta ruta todavía no tiene paradas asignadas.',
                action: FilledButton.icon(
                  onPressed: _assembling ? null : _assembleDailyRoute,
                  icon: const AnimatedAppIcon(AppIcon.checklist),
                  label: const Text('Armar ruta del día'),
                ),
              );
            }
            return Column(
              children: [
                RouteSummary(route: data),
                Expanded(
                  child: _showMap
                      ? RouteMap(route: data)
                      : RouteList(route: data),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Arma la ruta del día del vehículo a partir de las paradas del plan
  /// publicado y refresca la hoja de ruta. Escritura directa a la red; el
  /// backend ensambla desde el plan, por eso no se envían paradas manuales.
  Future<void> _assembleDailyRoute() async {
    final vehicleId = ref.read(assignedVehicleIdProvider);
    if (vehicleId == null) {
      showInfoSnack(context, 'Sin vehículo asignado.');
      return;
    }
    final date = ref.read(selectedDateProvider);
    setState(() => _assembling = true);
    try {
      await ref
          .read(assembleDailyRouteProvider)
          .call(vehicleId: vehicleId, date: date);
      if (!mounted) return;
      ref.invalidate(driverRouteProvider);
      showSuccessSnack(context, 'Ruta del día armada.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _assembling = false);
    }
  }
}
