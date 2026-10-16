import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/dispute_settlement_request.dart';
import '../../../../core/api/models/mark_settlement_paid_request.dart';
import '../../../../core/api/models/settlement.dart';
import '../../../../core/api/models/status.dart';
import '../../../../core/api/models/tariff.dart';
import '../../../../core/api/models/vehicle_class.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature que toca `logisticsApiProvider` / `api.carriers.*`.
///
/// Cada método espeja un endpoint del módulo de transportistas, devuelve el
/// modelo generado desde `.data` y normaliza el error de red a [ApiException].
/// Las escrituras de terreno (escaneos) no viven acá: pasan por la cola offline
/// desde sus casos de uso (Command).
class CarrierRemoteDataSource {
  CarrierRemoteDataSource(this._ref);

  final Ref _ref;

  /// Transportistas activos (para elegir el propio al entrar).
  Future<List<Carrier>> listCarriers() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .listCarriers(status: Status.active);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Liquidaciones del transportista elegido.
  Future<List<Settlement>> listSettlements(String carrierId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .listCarrierSettlements(carrierId: carrierId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Detalle de una liquidación.
  Future<Settlement> getSettlement(String settlementId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .getCarrierSettlement(settlementId: settlementId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Aprueba la liquidación (requiere red).
  Future<void> approveSettlement(String settlementId) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .carriers
          .approveCarrierSettlement(settlementId: settlementId);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Disputa la liquidación con un motivo (requiere red).
  Future<void> disputeSettlement(String settlementId, String reason) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .carriers
          .disputeCarrierSettlement(
            settlementId: settlementId,
            body: DisputeSettlementRequest(reason: reason),
          );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Marca la liquidación como pagada con una referencia (requiere red).
  Future<void> paySettlement(
    String settlementId,
    String paymentReference,
  ) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .carriers
          .payCarrierSettlement(
            settlementId: settlementId,
            body: MarkSettlementPaidRequest(paymentReference: paymentReference),
          );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Tarifa de un corredor para una clase de vehículo (solo lectura).
  Future<Tariff> getTariff({
    required String carrierId,
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required VehicleClass vehicleClass,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .getCarrierTariff(
            carrierId: carrierId,
            corridorFrom: corridorFrom,
            corridorTo: corridorTo,
            corridorType: corridorType,
            vehicleClass: vehicleClass,
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Sugiere la clase de vehículo y tarifa según el volumen (m³) del corredor.
  Future<Assignment> assignForVolume({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required double volumeM3,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .assignCarrierForVolume(
            corridorFrom: corridorFrom,
            corridorTo: corridorTo,
            corridorType: corridorType,
            volumeM3: volumeM3,
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Tarifa más barata disponible para un corredor (entre transportistas).
  Future<Tariff> cheapestTariff({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .carriers
          .cheapestCarrierTariff(
            corridorFrom: corridorFrom,
            corridorTo: corridorTo,
            corridorType: corridorType,
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final carrierRemoteDataSourceProvider = Provider<CarrierRemoteDataSource>(
  CarrierRemoteDataSource.new,
);
