import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/entities/due_maintenance_item.dart';
import '../../domain/repositories/fleet_ops_repository.dart';
import '../datasources/fleet_ops_data_source.dart';

/// Implementación del contrato de operaciones de flota. Delega en el data source.
class FleetOpsRepositoryImpl implements FleetOpsRepository {
  const FleetOpsRepositoryImpl(this._remote);

  final FleetOpsDataSource _remote;

  @override
  Future<VehicleCostSummary> getVehicleCostSummary({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _remote.getVehicleCostSummary(vehicleId: vehicleId, from: from, to: to);

  @override
  Future<Map<String, Object?>> getVehicleUtilization({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _remote.getVehicleUtilization(vehicleId: vehicleId, from: from, to: to);

  @override
  Future<FuelPrice> getCurrentFuelPrice({required FuelType fuelType}) =>
      _remote.getCurrentFuelPrice(fuelType: fuelType);

  @override
  Future<List<Refuel>> listVehicleRefuels({required String vehicleId}) =>
      _remote.listVehicleRefuels(vehicleId: vehicleId);

  @override
  Future<List<OdometerReading>> listOdometerReadings({
    required String vehicleId,
  }) => _remote.listOdometerReadings(vehicleId: vehicleId);

  @override
  Future<List<DueMaintenanceItem>> listDueMaintenance() =>
      _remote.listDueMaintenance();

  @override
  Future<AcceptedEnvelope> recordRefuel(RecordRefuelRequest request) =>
      _remote.recordRefuel(request);

  @override
  Future<void> recordOdometer(RecordOdometerRequest request) =>
      _remote.recordOdometer(request);
}

final fleetOpsRepositoryProvider = Provider<FleetOpsRepository>(
  (ref) => FleetOpsRepositoryImpl(ref.watch(fleetOpsDataSourceProvider)),
);
