import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart' hide DueMaintenanceItem;
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
      // El cliente ya lo trae tipado; la pantalla lo consume como mapa (claves
      // del backend), así que se vuelve a JSON plano.
      final decoded = jsonDecode(jsonEncode(response.data.toJson()));
      return decoded is Map
          ? decoded.map((key, value) => MapEntry('$key', value))
          : const <String, Object?>{};
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

  /// [from]/[to] acotan el historial que baja el teléfono (el endpoint los
  /// acepta; sin ellos devuelve todas las cargas del camión).
  Future<List<Refuel>> listVehicleRefuels({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.listFleetRefuels(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );
      return [...response.data]
        ..sort((a, b) => b.refueledAt.compareTo(a.refueledAt));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// [from]/[to] acotan el historial, igual que en [listVehicleRefuels].
  Future<List<OdometerReading>> listOdometerReadings({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleetOps.listFleetOdometerReadings(
        vehicleId: vehicleId,
        from: from,
        to: to,
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
      // El cliente ya trae el ítem tipado: se pasa al modelo del feature (que
      // calcula la urgencia y los textos de la tarjeta).
      for (final raw in response.data) {
        items.add(
          DueMaintenanceItem(
            vehicleId: raw.vehicleId,
            plate: raw.vehiclePlate,
            serviceKind: MaintenancePlanServiceKind.fromJson(
              raw.serviceKind.json ?? '',
            ),
            nextDueAt: raw.nextDueAt,
            nextDueKm: raw.nextDueKm,
            currentKm: raw.currentOdometerKm,
            remainingKm: raw.remainingKm,
            remainingDays: raw.daysRemaining,
            overdue: raw.overdue,
          ),
        );
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
