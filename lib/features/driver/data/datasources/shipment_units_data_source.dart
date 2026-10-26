import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Bultos esperados de un envío (`GET /app/tracking/shipments/{id}/units`).
/// Lo usa el escaneo de carga/descarga para avisar al instante cuando se lee un
/// bulto ajeno y para mostrar "Bulto N/M".
class ShipmentUnitsDataSource {
  const ShipmentUnitsDataSource(this._ref);

  final Ref _ref;

  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .tracking
          .getShipmentUnits(shipmentId: shipmentId);
      return response.data.units;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final shipmentUnitsDataSourceProvider = Provider<ShipmentUnitsDataSource>(
  ShipmentUnitsDataSource.new,
);
