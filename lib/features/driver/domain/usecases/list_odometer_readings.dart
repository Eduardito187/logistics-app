import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): lecturas de odómetro del vehículo en un rango de fechas.
class ListOdometerReadings {
  const ListOdometerReadings(this._repo);

  final FleetOpsRepository _repo;

  /// [from]/[to]: rango (inclusive) que se quiere ver. Obligatorio para no
  /// bajar años de historial en el teléfono.
  Future<List<OdometerReading>> call({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _repo.listOdometerReadings(vehicleId: vehicleId, from: from, to: to);
}

final listOdometerReadingsProvider = Provider<ListOdometerReadings>(
  (ref) => ListOdometerReadings(ref.watch(fleetOpsRepositoryProvider)),
);
