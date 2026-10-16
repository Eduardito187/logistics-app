import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): cargas de combustible recientes del vehículo.
class ListVehicleRefuels {
  const ListVehicleRefuels(this._repo);

  final FleetOpsRepository _repo;

  Future<List<Refuel>> call({required String vehicleId}) =>
      _repo.listVehicleRefuels(vehicleId: vehicleId);
}

final listVehicleRefuelsProvider = Provider<ListVehicleRefuels>(
  (ref) => ListVehicleRefuels(ref.watch(fleetOpsRepositoryProvider)),
);
