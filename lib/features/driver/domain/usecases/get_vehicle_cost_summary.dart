import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): resumen de costos (TCO + costo por km) del vehículo en un rango.
class GetVehicleCostSummary {
  const GetVehicleCostSummary(this._repo);

  final FleetOpsRepository _repo;

  Future<VehicleCostSummary> call({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _repo.getVehicleCostSummary(vehicleId: vehicleId, from: from, to: to);
}

final getVehicleCostSummaryProvider = Provider<GetVehicleCostSummary>(
  (ref) => GetVehicleCostSummary(ref.watch(fleetOpsRepositoryProvider)),
);
