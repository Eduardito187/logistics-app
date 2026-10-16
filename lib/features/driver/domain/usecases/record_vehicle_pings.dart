import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/vehicle_telemetry_repository_impl.dart';
import '../repositories/vehicle_telemetry_repository.dart';

/// Command (CQRS): envía un lote de posiciones GPS del vehículo (escritura
/// directa a la red). Propaga `ApiException` ante un error.
class RecordVehiclePings {
  const RecordVehiclePings(this._repo);

  final VehicleTelemetryRepository _repo;

  Future<void> call({
    required String vehicleId,
    required List<VehiclePing> pings,
  }) => _repo.recordVehiclePings(vehicleId: vehicleId, pings: pings);
}

final recordVehiclePingsProvider = Provider<RecordVehiclePings>(
  (ref) => RecordVehiclePings(ref.watch(vehicleTelemetryRepositoryProvider)),
);
