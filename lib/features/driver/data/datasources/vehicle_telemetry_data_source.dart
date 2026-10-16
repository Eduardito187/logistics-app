import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature que toca `api.telemetry`. Espeja el despacho en lote
/// de posiciones del vehículo y normaliza el error de Dio a [ApiException].
class VehicleTelemetryDataSource {
  const VehicleTelemetryDataSource(this._ref);

  final Ref _ref;

  Future<void> recordVehiclePings({
    required String vehicleId,
    required List<VehiclePing> pings,
  }) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      await api.telemetry.recordAppVehiclePings(
        body: AppTelemetryPingsRequestBody(vehicleId: vehicleId, pings: pings),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final vehicleTelemetryDataSourceProvider = Provider<VehicleTelemetryDataSource>(
  VehicleTelemetryDataSource.new,
);
