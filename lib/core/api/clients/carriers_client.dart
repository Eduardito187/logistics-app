// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/carrier_document.dart';
import '../models/corridor_type.dart';
import '../models/dispute_settlement_request.dart';
import '../models/get_app_carriers_assignment_response.dart';
import '../models/get_app_carriers_carrier_id_tariff_response.dart';
import '../models/get_app_carriers_response.dart';
import '../models/get_app_carriers_settlements_response.dart';
import '../models/get_app_carriers_settlements_settlement_id_response.dart';
import '../models/get_app_carriers_tariffs_cheapest_response.dart';
import '../models/mark_settlement_paid_request.dart';
import '../models/rate_carrier_request.dart';
import '../models/register_carrier_request.dart';
import '../models/set_tariff_request.dart';
import '../models/settlement_status.dart';
import '../models/status.dart';
import '../models/submit_settlement_request.dart';
import '../models/vehicle_class.dart';

part 'carriers_client.g.dart';

@RestApi()
abstract class CarriersClient {
  factory CarriersClient(Dio dio, {String? baseUrl}) = _CarriersClient;

  /// List carriers.
  ///
  /// Supports optional offset or cursor pagination (E-02). Without pagination parameters the full collection is returned unchanged; otherwise it is sliced and a `meta` object is added.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/carriers')
  Future<GetAppCarriersResponse> listCarriers({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') Status? status,
    @Query('cursor') String? cursor,
  });

  /// Assign a corridor to a vehicle class by volume.
  ///
  /// Devuelve la clase de vehículo que corresponde al volumen (m³) y la tarifa más barata disponible para esa clase en el corredor (consolidación entre departamentos).
  @GET('/app/carriers/assignment')
  Future<GetAppCarriersAssignmentResponse> assignCarrierForVolume({
    @Query('corridor_from') required String corridorFrom,
    @Query('corridor_to') required String corridorTo,
    @Query('corridor_type') required CorridorType corridorType,
    @Query('volume_m3') required double volumeM3,
  });

  /// List carrier settlements
  @GET('/app/carriers/settlements')
  Future<GetAppCarriersSettlementsResponse> listCarrierSettlements({
    @Query('carrier_id') String? carrierId,
    @Query('status') SettlementStatus? status,
  });

  /// Get a carrier settlement.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @GET('/app/carriers/settlements/{settlementId}')
  Future<GetAppCarriersSettlementsSettlementIdResponse> getCarrierSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Approve a settlement.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/approve')
  Future<AcceptedEnvelope> approveCarrierSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Dispute a settlement.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/dispute')
  Future<AcceptedEnvelope> disputeCarrierSettlement({
    @Path('settlementId') required String settlementId,
    @Body() required DisputeSettlementRequest body,
  });

  /// Mark a settlement as paid.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/pay')
  Future<AcceptedEnvelope> payCarrierSettlement({
    @Path('settlementId') required String settlementId,
    @Body() required MarkSettlementPaidRequest body,
  });

  /// Cheapest tariff for a corridor
  @GET('/app/carriers/tariffs/cheapest')
  Future<GetAppCarriersTariffsCheapestResponse> cheapestCarrierTariff({
    @Query('corridor_from') required String corridorFrom,
    @Query('corridor_to') required String corridorTo,
    @Query('corridor_type') required CorridorType corridorType,
  });

  /// Get a carrier tariff for a corridor and vehicle class.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @GET('/app/carriers/{carrierId}/tariff')
  Future<GetAppCarriersCarrierIdTariffResponse> getCarrierTariff({
    @Path('carrierId') required String carrierId,
    @Query('corridor_from') required String corridorFrom,
    @Query('corridor_to') required String corridorTo,
    @Query('corridor_type') required CorridorType corridorType,
    @Query('vehicle_class') required VehicleClass vehicleClass,
  });

  /// Register a third-party carrier.
  ///
  /// Da de alta un transportista tercero. El id lo genera el dominio; la respuesta es un acuse 202.
  @POST('/integrations/carriers')
  Future<AcceptedEnvelope> registerCarrier({
    @Body() required RegisterCarrierRequest body,
  });

  /// Attach a document to a settlement.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/integrations/carriers/settlements/{settlementId}/documents')
  Future<AcceptedEnvelope> attachSettlementDocument({
    @Path('settlementId') required String settlementId,
    @Body() required CarrierDocument body,
  });

  /// Rate a carrier.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @POST('/integrations/carriers/{carrierId}/ratings')
  Future<AcceptedEnvelope> rateCarrier({
    @Path('carrierId') required String carrierId,
    @Body() required RateCarrierRequest body,
  });

  /// Reactivate a suspended carrier.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @POST('/integrations/carriers/{carrierId}/reactivate')
  Future<AcceptedEnvelope> reactivateCarrier({
    @Path('carrierId') required String carrierId,
  });

  /// Submit a carrier settlement for a corridor and period.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @POST('/integrations/carriers/{carrierId}/settlements')
  Future<AcceptedEnvelope> submitCarrierSettlement({
    @Path('carrierId') required String carrierId,
    @Body() required SubmitSettlementRequest body,
  });

  /// Suspend a carrier.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @POST('/integrations/carriers/{carrierId}/suspend')
  Future<AcceptedEnvelope> suspendCarrier({
    @Path('carrierId') required String carrierId,
  });

  /// Set a carrier tariff for a corridor and vehicle class.
  ///
  /// [carrierId] - UUID v7 del transportista.
  @POST('/integrations/carriers/{carrierId}/tariffs')
  Future<AcceptedEnvelope> setCarrierTariff({
    @Path('carrierId') required String carrierId,
    @Body() required SetTariffRequest body,
  });
}
