import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/route_progress.dart';
import '../domain/usecases/assemble_daily_route.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_vehicle_gate.dart';
import 'odometer_screen.dart';
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
    final route = ref.watch(driverRouteProvider);
    // "Armar ruta del día" solo tiene sentido cuando NO hay ruta todavía: si ya
    // está armada (tiene paradas), re-armarla el backend la rechaza (422) y
    // confunde. Con ruta cargada, el botón del header se oculta (el estado vacío
    // ya ofrece su propio botón para armarla).
    final routeHasStops = route.value?.stops.isNotEmpty ?? false;
    return DriverVehicleGate(
      title: 'Mi ruta de hoy',
      actions: [
        if (!routeHasStops)
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
            // Cuando ya no quedan paradas pendientes, se ofrece cerrar la ruta
            // tomando el odómetro de LLEGADA al centro de distribución (el
            // odómetro solo se pide al salir —en el checklist— y al llegar).
            // Item por item con el estado efectivo (incluye lo resuelto en este
            // teléfono), igual que el resumen y la entrega en curso.
            final settled = ref.watch(locallySettledStopsProvider);
            final allDone = RouteProgress.of(data, settled).isComplete;
            return Column(
              children: [
                RouteSummary(route: data),
                Expanded(
                  child: _showMap
                      ? RouteMap(route: data, settled: settled)
                      : RouteList(route: data),
                ),
                if (allDone)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      // Solo aparece cuando YA se atendieron todas las paradas
                      // (item por item). Sin texto explicativo: el botón lleva al
                      // odómetro de llegada y eso ya deja clara la intención.
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _finishRoute,
                          icon: const AnimatedAppIcon(AppIcon.speed),
                          label: const Text('Cerrar ruta del día'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Abre la lectura de odómetro de LLEGADA al centro de distribución (cierre de
  /// la ruta), con `source: arrival` (simétrico de la salida del checklist).
  void _finishRoute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OdometerScreen(
          source: RecordOdometerRequestSource.arrival,
          title: 'Odómetro de llegada',
          intro:
              'Registrá los kilómetros al llegar al centro de distribución, '
              'para cerrar la ruta del día.',
          initialNote: 'Llegada al CD',
        ),
      ),
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
      showSuccessSnack(
        context,
        'Ruta del día armada.',
        bottomClearance: kBottomActionClearance,
      );
    } on ApiException catch (e) {
      // Aviso elevado para no tapar los botones de zoom del mapa.
      if (mounted) {
        showErrorSnack(context, e, bottomClearance: kBottomActionClearance);
      }
    } finally {
      if (mounted) setState(() => _assembling = false);
    }
  }
}
