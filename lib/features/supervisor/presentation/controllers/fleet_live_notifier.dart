import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../domain/usecases/get_live_fleet.dart';

/// Posiciones en vivo de la flota (telemetría).
///
/// La lista se pide una vez y después se mantiene al día con los eventos de
/// tiempo real ([apply] / [remove]), sin volver a pedirla.
class FleetLive extends AsyncNotifier<List<VehicleLive>> {
  @override
  Future<List<VehicleLive>> build() => ref.watch(getLiveFleetProvider)();

  /// Aplica la posición nueva de un camión (lo agrega si no estaba). Una
  /// lectura más vieja que la que ya se muestra se descarta.
  void apply(VehicleLive next) {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((v) => v.vehicleId == next.vehicleId);
    if (index < 0) {
      state = AsyncData([...current, next]);
      return;
    }
    final old = current[index];
    if (old.recordedAt.isAfter(next.recordedAt)) return;
    state = AsyncData([...current]..[index] = _merge(old, next));
  }

  /// Un camión se dio de baja en la flota.
  void remove(String vehicleId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final vehicle in current)
        if (vehicle.vehicleId != vehicleId) vehicle,
    ]);
  }

  /// La telemetría manda el evento; los datos fijos del camión (placa, chofer,
  /// sede) se conservan si el evento no los trae.
  static VehicleLive _merge(VehicleLive old, VehicleLive next) => VehicleLive(
    vehicleId: next.vehicleId,
    lat: next.lat,
    lng: next.lng,
    moving: next.moving,
    recordedAt: next.recordedAt,
    speedKph: next.speedKph,
    heading: next.heading,
    ignition: next.ignition,
    routeId: next.routeId,
    updatedAt: next.updatedAt ?? old.updatedAt,
    plate: next.plate ?? old.plate,
    driverId: next.driverId ?? old.driverId,
    driverName: next.driverName ?? old.driverName,
    baseNodeId: next.baseNodeId ?? old.baseNodeId,
    baseNodeName: next.baseNodeName ?? old.baseNodeName,
    city: next.city ?? old.city,
  );
}

final fleetLiveProvider =
    AsyncNotifierProvider.autoDispose<FleetLive, List<VehicleLive>>(
      FleetLive.new,
    );
