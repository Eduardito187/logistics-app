import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature que toca `api.fleet`. Espeja los endpoints de flota
/// usados por el chofer y normaliza el error de Dio a [ApiException].
class FleetDataSource {
  const FleetDataSource(this._ref);

  final Ref _ref;

  /// Asignación (vehículo + tripulación) del chofer autenticado para [date]. El
  /// chofer NO elige: se le asigna. El backend responde 404 cuando la cuenta no
  /// es chofer o no tiene tripulación armada para esa fecha; se normaliza a
  /// [ApiException] con status 404 (incluido el caso `data` nulo en un 200).
  Future<MyCrew> getMyCrew(DateTime date) async {
    // El backend espera la fecha en `Y-m-d`; el cliente generado la serializa
    // como datetime ISO (`toIso8601String`) y el backend responde 422. Hasta
    // regenerar el cliente con el tipo correcto, se llama con Dio directo
    // reusando el modelo generado para el parseo (no se escribe DTO a mano).
    final dio = _ref.read(dioProvider);
    final ymd =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    try {
      final res = await dio.get<Map<String, Object?>>(
        '/app/fleet/my-crew',
        queryParameters: {'date': ymd},
      );
      final data = res.data;
      if (data == null) {
        throw const ApiException(status: 404, title: 'Sin asignación');
      }
      final crew = GetAppFleetMyCrewResponse.fromJson(data).data;
      if (crew == null) {
        throw const ApiException(status: 404, title: 'Sin asignación');
      }
      return crew;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Driver>> listActiveDrivers() async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleet.fleetListDrivers(onlyActive: true);
      return response.data ?? const <Driver>[];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Data5?> conductPreTripChecklist(
    ConductPreTripChecklistRequest request,
  ) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      final response = await api.fleet.fleetConductPreTripChecklist(
        body: request,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final fleetDataSourceProvider = Provider<FleetDataSource>(FleetDataSource.new);
