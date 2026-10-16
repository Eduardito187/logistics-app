import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature que toca `api.execution` (y el detalle del envío en
/// `api.shipments`). Cada método espeja un endpoint, devuelve el modelo del
/// contrato desde `.data` y normaliza el error de Dio a [ApiException].
class DriverRouteDataSource {
  const DriverRouteDataSource(this._ref);

  final Ref _ref;

  Future<DriverRoute> getDriverRoute({
    required String vehicleId,
    required DateTime date,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.execution.getDriverRoute(
        vehicleId: vehicleId,
        date: date,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Detalle del envío: cliente, teléfono, dirección y productos (líneas).
  Future<Shipment> getShipment({required String shipmentId}) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.shipments.getShipment(shipment: shipmentId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Delivery>> listVehicleDeliveries({
    required String vehicleId,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.execution.listVehicleDeliveries(
        vehicleId: vehicleId,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Delivery> getDeliveryState({required String shipmentId}) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.execution.getDeliveryState(
        shipmentId: shipmentId,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> assembleDailyRoute({
    required String vehicleId,
    required AppVehiclesVehicleIdRouteRequestBody body,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      await api.execution.assembleDailyRoute(vehicleId: vehicleId, body: body);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final driverRouteDataSourceProvider = Provider<DriverRouteDataSource>(
  DriverRouteDataSource.new,
);
