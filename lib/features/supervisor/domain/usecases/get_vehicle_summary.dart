import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: resumen diario de telemetría de un vehículo.
class GetVehicleSummary {
  const GetVehicleSummary(this._repo);

  final SupervisorRepository _repo;

  Future<VehicleTelemetrySummary> call(String vehicleId) =>
      _repo.getVehicleTelemetrySummary(vehicleId);
}

final getVehicleSummaryProvider = Provider<GetVehicleSummary>(
  (ref) => GetVehicleSummary(ref.watch(supervisorRepositoryProvider)),
);
