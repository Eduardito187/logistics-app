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
import '../models/get_app_carriers_corridors_response.dart';
import '../models/get_app_carriers_me_assignments_response.dart';
import '../models/get_app_carriers_response.dart';
import '../models/get_app_carriers_settlements_response.dart';
import '../models/get_app_carriers_settlements_settlement_id_response.dart';
import '../models/get_app_carriers_tariffs_cheapest_response.dart';
import '../models/mark_settlement_paid_request.dart';
import '../models/post_app_carriers_trips_trip_id_close_response.dart';
import '../models/post_app_carriers_trips_trip_id_start_response.dart';
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
  /// Supports optional offset or cursor pagination (E-02). Without pagination parameters the full collection is returned unchanged; otherwise it is sliced and a `meta` object is added. Alcance server-side: oficina (admin/supervisor) ve todos; el rol transportista recibe SOLO su propio transportista (users.carrier_id; leerlo de /app/auth/me → user.carrier). Otros roles o un transportista sin vínculo → 403.
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

  /// List trips assigned to the carrier (with load).
  ///
  /// Rol transportista: solo los viajes de su transportista (users.carrier_id; se ignora carrier_id). Oficina: todos, filtro opcional carrier_id. Por defecto solo vigentes (scheduled,in_progress).
  ///
  /// [carrierId] - Filtro de oficina; ignorado para transportista.
  ///
  /// [status] - Lista separada por coma: scheduled,in_progress,closed,cancelled.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/carriers/me/assignments')
  Future<GetAppCarriersMeAssignmentsResponse> listCarrierAssignments({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('carrier_id') String? carrierId,
    @Query('status') String? status,
    @Query('cursor') String? cursor,
  });

  /// Start a carrier trip (idempotent).
  ///
  /// Oficina o el transportista dueño del viaje. Repetir devuelve el mismo started_at.
  @POST('/app/carriers/trips/{tripId}/start')
  Future<PostAppCarriersTripsTripIdStartResponse> startCarrierTrip({
    @Path('tripId') required String tripId,
  });

  /// Close a carrier trip (idempotent).
  ///
  /// Oficina o el transportista dueño. Solo un viaje en ruta; repetir devuelve el mismo closed_at.
  @POST('/app/carriers/trips/{tripId}/close')
  Future<PostAppCarriersTripsTripIdCloseResponse> closeCarrierTrip({
    @Path('tripId') required String tripId,
  });

  /// Assign a corridor to a vehicle class by volume.
  ///
  /// Solo oficina (admin/supervisor): compara tarifas de todos los transportistas. Otros roles → 403.
  /// Devuelve la clase de vehículo que corresponde al volumen (m³) y la tarifa más barata disponible para esa clase en el corredor (consolidación entre departamentos).
  @GET('/app/carriers/assignment')
  Future<GetAppCarriersAssignmentResponse> assignCarrierForVolume({
    @Query('corridor_from') required String corridorFrom,
    @Query('corridor_to') required String corridorTo,
    @Query('corridor_type') required CorridorType corridorType,
    @Query('volume_m3') required double volumeM3,
  });

  /// List carrier settlements.
  ///
  /// Alcance server-side: oficina (admin/supervisor) ve todas y puede filtrar por `carrier_id`. Para el rol transportista el `carrier_id` enviado se IGNORA y se devuelven solo las liquidaciones de su transportista (users.carrier_id). Transportista sin vínculo u otros roles → 403.
  ///
  /// [carrierId] - Filtro de oficina. Ignorado para el rol transportista (se fuerza el suyo).
  ///
  /// [periodFrom] - Inclusive lower bound (Y-m-d). Matches settlements whose billing month (YYYY-MM) is >= this date's month.
  ///
  /// [periodTo] - Inclusive upper bound (Y-m-d), must be >= period_from. Matches settlements whose billing month is <= this date's month.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/carriers/settlements')
  Future<GetAppCarriersSettlementsResponse> listCarrierSettlements({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('carrier_id') String? carrierId,
    @Query('status') SettlementStatus? status,
    @Query('period_from') DateTime? periodFrom,
    @Query('period_to') DateTime? periodTo,
    @Query('cursor') String? cursor,
  });

  /// List tariffed carrier corridors.
  ///
  /// Distinct corridors built from carrier tariffs, with the tariffed vehicle classes. `from`/`to` are the exact slugs accepted by GET /app/carriers/{carrierId}/tariff (they stay slugs; they are not network node ids); `from_label`/`to_label` are display-only (network node name when the slug matches a node code/id, otherwise the humanized slug). Carrier role: only its own carrier (carrier_id ignored). Office: all, optional carrier_id. Pagination is opt-in (no meta without page/cursor/per_page).
  ///
  /// [carrierId] - Office filter. Ignored for the carrier role.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/carriers/corridors')
  Future<GetAppCarriersCorridorsResponse> listCarrierCorridors({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('carrier_id') String? carrierId,
    @Query('cursor') String? cursor,
  });

  /// Get a carrier settlement.
  ///
  /// Oficina: cualquier liquidación. Rol transportista: solo las de su transportista; una ajena (o inexistente) responde 403 sin revelar si existe.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @GET('/app/carriers/settlements/{settlementId}')
  Future<GetAppCarriersSettlementsSettlementIdResponse> getCarrierSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Approve a settlement.
  ///
  /// Solo oficina (admin/supervisor). El transportista no aprueba su propia liquidación (segregación de funciones) → 403.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/approve')
  Future<AcceptedEnvelope> approveCarrierSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Dispute a settlement.
  ///
  /// Oficina: cualquier liquidación. Rol transportista: solo las de su transportista; ajena → 403.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/dispute')
  Future<AcceptedEnvelope> disputeCarrierSettlement({
    @Path('settlementId') required String settlementId,
    @Body() required DisputeSettlementRequest body,
  });

  /// Mark a settlement as paid.
  ///
  /// Solo oficina (admin/supervisor): el pago lo registra finanzas, no el proveedor. Rol transportista → 403.
  ///
  /// [settlementId] - UUID v7 de la liquidación.
  @POST('/app/carriers/settlements/{settlementId}/pay')
  Future<AcceptedEnvelope> payCarrierSettlement({
    @Path('settlementId') required String settlementId,
    @Body() required MarkSettlementPaidRequest body,
  });

  /// Cheapest tariff for a corridor.
  ///
  /// Solo oficina (admin/supervisor) — compara tarifas de todos los transportistas. Otros roles → 403.
  @GET('/app/carriers/tariffs/cheapest')
  Future<GetAppCarriersTariffsCheapestResponse> cheapestCarrierTariff({
    @Query('corridor_from') required String corridorFrom,
    @Query('corridor_to') required String corridorTo,
    @Query('corridor_type') required CorridorType corridorType,
  });

  /// Get a carrier tariff for a corridor and vehicle class.
  ///
  /// Oficina — cualquier transportista. Rol transportista — solo `{carrierId}` propio; ajeno → 403.
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
