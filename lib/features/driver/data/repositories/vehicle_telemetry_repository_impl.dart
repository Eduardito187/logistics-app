import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/repositories/vehicle_telemetry_repository.dart';
import '../datasources/vehicle_telemetry_data_source.dart';

/// Implementación del contrato de telemetría del vehículo. Delega en el data
/// source.
class VehicleTelemetryRepositoryImpl implements VehicleTelemetryRepository {
  const VehicleTelemetryRepositoryImpl(this._remote);

  final VehicleTelemetryDataSource _remote;

  @override
  Future<void> recordVehiclePings({
    required String vehicleId,
    required List<VehiclePing> pings,
  }) => _remote.recordVehiclePings(vehicleId: vehicleId, pings: pings);
}

final vehicleTelemetryRepositoryProvider = Provider<VehicleTelemetryRepository>(
  (ref) => VehicleTelemetryRepositoryImpl(
    ref.watch(vehicleTelemetryDataSourceProvider),
  ),
);
