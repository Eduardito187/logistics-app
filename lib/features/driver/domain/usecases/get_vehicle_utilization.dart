import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): utilización del vehículo en un rango, como mapa de métricas.
class GetVehicleUtilization {
  const GetVehicleUtilization(this._repo);

  final FleetOpsRepository _repo;

  Future<Map<String, Object?>> call({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _repo.getVehicleUtilization(vehicleId: vehicleId, from: from, to: to);
}

final getVehicleUtilizationProvider = Provider<GetVehicleUtilization>(
  (ref) => GetVehicleUtilization(ref.watch(fleetOpsRepositoryProvider)),
);
