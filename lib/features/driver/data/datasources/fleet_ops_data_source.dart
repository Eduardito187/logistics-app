import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/due_maintenance_item.dart';

/// Única clase del feature que toca `api.fleetOps`. Espeja los endpoints de
/// operaciones de flota del chofer, aplica el orden/parseo esperado por la UI y
/// normaliza el error de Dio a [ApiException].
class FleetOpsDataSource {
  const FleetOpsDataSource(this._ref);

  final Ref _ref;

  Future<VehicleCostSummary> getVehicleCostSummary({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.getFleetVehicleCostSummary(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, Object?>> getVehicleUtilization({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.getFleetVehicleUtilization(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );
      final Object? data = response.data;
      if (data is Map) {
        return data.map((key, value) => MapEntry('$key', value));
      }
      return const <String, Object?>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FuelPrice> getCurrentFuelPrice({required FuelType fuelType}) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.getCurrentFleetFuelPrice(
        fuelType: fuelType,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Refuel>> listVehicleRefuels({required String vehicleId}) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.listFleetRefuels(
        vehicleId: vehicleId,
      );
      return [...response.data]
        ..sort((a, b) => b.refueledAt.compareTo(a.refueledAt));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<OdometerReading>> listOdometerReadings({
    required String vehicleId,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.listFleetOdometerReadings(
        vehicleId: vehicleId,
      );
      return [...response.data]..sort((a, b) => b.readAt.compareTo(a.readAt));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DueMaintenanceItem>> listDueMaintenance() async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.listFleetDueMaintenance();
      final items = <DueMaintenanceItem>[];
      for (final raw in response.data) {
        if (raw is Map) {
          items.add(DueMaintenanceItem.fromMap(raw.cast<String, Object?>()));
        }
      }
      items.sort((a, b) => a.urgency.order.compareTo(b.urgency.order));
      return items;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AcceptedEnvelope> recordRefuel(RecordRefuelRequest request) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      // Devuelve el 202 (`AcceptedEnvelope`) para que la UI distinga "aceptado,
      // en proceso" de un éxito ya aplicado.
      return await api.fleetOps.recordFleetRefuel(body: request);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> recordOdometer(RecordOdometerRequest request) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      await api.fleetOps.recordFleetOdometer(body: request);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final fleetOpsDataSourceProvider = Provider<FleetOpsDataSource>(
  FleetOpsDataSource.new,
);
