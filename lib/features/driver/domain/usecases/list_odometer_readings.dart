import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): lecturas de odómetro recientes del vehículo.
class ListOdometerReadings {
  const ListOdometerReadings(this._repo);

  final FleetOpsRepository _repo;

  Future<List<OdometerReading>> call({required String vehicleId}) =>
      _repo.listOdometerReadings(vehicleId: vehicleId);
}

final listOdometerReadingsProvider = Provider<ListOdometerReadings>(
  (ref) => ListOdometerReadings(ref.watch(fleetOpsRepositoryProvider)),
);
