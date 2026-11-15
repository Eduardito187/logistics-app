// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/delivery_mode.dart';
import '../models/get_app_kpis_daily_response.dart';
import '../models/get_app_shipments_low_confidence_addresses_response.dart';
import '../models/get_app_shipments_response.dart';
import '../models/get_app_shipments_shipment_response.dart';
import '../models/get_app_shipments_summary_response.dart';
import '../models/order_lookup_response.dart';
import '../models/order_source.dart';
import '../models/post_app_shipments_reschedule_preview_response.dart';
import '../models/post_app_shipments_reschedule_response.dart';
import '../models/post_app_shipments_shipment_geocode_response.dart';
import '../models/post_integrations_shipments_import_response.dart';
import '../models/receive_shipment_accepted.dart';
import '../models/receive_shipment_request.dart';
import '../models/reschedule_shipments_request.dart';
import '../models/shipment_status.dart';

part 'shipments_client.g.dart';

@RestApi()
abstract class ShipmentsClient {
  factory ShipmentsClient(Dio dio, {String? baseUrl}) = _ShipmentsClient;

  /// Aggregated shipment board summary (SQL aggregates, cached ~45 s).
  ///
  /// [destinationNodeId] - Forced to the own node for the Store role.
  @GET('/app/shipments/summary')
  Future<GetAppShipmentsSummaryResponse> getShipmentSummary({
    @Query('date') DateTime? date,
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
    @Query('destination_node_id') String? destinationNodeId,
    @Query('delivery_mode') DeliveryMode? deliveryMode,
  });

  /// Operational KPIs of one day, scoped server-side by role (driver / fleet / node).
  ///
  /// [date] - Defaults to today (America/La_Paz).
  ///
  /// [nodeId] - Supervisor/admin only.
  ///
  /// [vehicleId] - Supervisor/admin only.
  ///
  /// [driverId] - Supervisor/admin only (fleet driver id).
  @GET('/app/kpis/daily')
  Future<GetAppKpisDailyResponse> getDailyKpis({
    @Query('date') DateTime? date,
    @Query('node_id') String? nodeId,
    @Query('vehicle_id') String? vehicleId,
    @Query('driver_id') String? driverId,
  });

  /// Open read-only order lookup by order code or label id (any app role).
  ///
  /// Read-only lookup available to every authenticated app role, with NO role scope: a store finds orders of another store and a picker finds orders of another city. `q` is resolved in this order: exact order code (external id or order reference, case-insensitive), then a scanned label id, then a partial text match (3+ characters). Returns up to 10 shipments; an order split into several shipments returns all of them. `can_process` tells whether the caller could operate each shipment (false = view only).
  ///
  /// [q] - Order code or scanned label id.
  @GET('/app/orders/lookup')
  Future<OrderLookupResponse> lookupOrders({@Query('q') required String q});

  /// List received orders, optionally filtered by status and source.
  ///
  /// Supports optional offset or cursor pagination (E-02). Without any pagination parameter the full collection is returned unchanged; with `page`/`per_page` or `cursor` the response is sliced and a `meta` object is added. Cursor pagination is preferred for this growing collection and uses keyset (seek by shipment `id`, a time-ordered UUID v7): `next_cursor` is an opaque token, so a deep page costs the same as the first one instead of scanning and discarding rows.
  ///
  /// [status] - One or more statuses, case-insensitive, sent comma-separated (status=planned,received). The server also accepts the repeated `status[]=` form. Unknown values return 422.
  ///
  /// [include] - Comma-separated extras. `count_by_status` adds meta.count_by_status (same filters except status).
  ///
  /// [q] - Búsqueda en el servidor por código de pedido (external_id / order_reference), nombre o documento del cliente. Sin distinguir mayúsculas; coincide por contenido. Se combina con los demás filtros.
  ///
  /// [city] - Ciudad (texto). Coincide, sin distinguir mayúsculas, con la dirección del envío o con el departamento / nombre de su nodo destino. Los envíos no guardan la ciudad en un campo propio.
  ///
  /// [vehicleId] - Solo envíos asignados a ese vehículo (entrega abierta o parada en una ruta suya).
  ///
  /// [deliveryDate] - Atajo de un solo día; equivale a delivery_date_from = delivery_date_to.
  ///
  /// [readyForPickup] - true = solo pedidos cuya recepción en su tienda destino ya se concilió y que todavía no se entregaron (el cliente puede pasar a retirarlos). Para la bandeja de recojo usarlo junto con delivery_mode=store_pickup. Accepts true/false/1/0.
  ///
  /// [pendingPreparation] - true = only assigned shipments (PLANNED / IN_EXECUTION) whose delivery has no PREPARATION scan yet (includes labels emitted but not prepared). Accepts true/false/1/0. Not applied to meta.count_by_status.
  ///
  /// [deliveryDateFrom] - Promised delivery date lower bound (inclusive). Shipments without a date are excluded.
  ///
  /// [deliveryDateTo] - Promised delivery date upper bound (inclusive); must be on or after delivery_date_from.
  ///
  /// [destinationNodeId] - Filtra por nodo destino. Para el rol Tienda se fuerza server-side a su nodo asignado e ignora este parámetro, de modo que una tienda solo ve sus propios envíos.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/shipments')
  Future<GetAppShipmentsResponse> listShipments({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') List<ShipmentStatus>? status,
    @Query('delivery_mode') DeliveryMode? deliveryMode,
    @Query('include') String? include,
    @Query('q') String? q,
    @Query('city') String? city,
    @Query('vehicle_id') String? vehicleId,
    @Query('delivery_date') DateTime? deliveryDate,
    @Query('ready_for_pickup') bool? readyForPickup,
    @Query('pending_preparation') bool? pendingPreparation,
    @Query('source') OrderSource? source,
    @Query('delivery_date_from') DateTime? deliveryDateFrom,
    @Query('delivery_date_to') DateTime? deliveryDateTo,
    @Query('destination_node_id') String? destinationNodeId,
    @Query('cursor') String? cursor,
  });

  /// List orders whose delivery address has low confidence.
  ///
  /// Supports optional offset or cursor pagination (E-02); see listShipments. Without pagination parameters the full collection is returned unchanged.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/shipments/low-confidence-addresses')
  Future<GetAppShipmentsLowConfidenceAddressesResponse>
  listLowConfidenceAddresses({
    @Query('cursor') String? cursor,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Get a received order by id
  @GET('/app/shipments/{shipment}')
  Future<GetAppShipmentsShipmentResponse> getShipment({
    @Path('shipment') required String shipment,
  });

  /// Re-geocode (recalculate the confidence of) an order's delivery address
  @POST('/app/shipments/{shipment}/geocode')
  Future<PostAppShipmentsShipmentGeocodeResponse> geocodeShipmentAddress({
    @Path('shipment') required String shipment,
  });

  /// Receive an order into the platform (idempotent by source + external reference).
  ///
  /// Único punto de ingreso de pedidos desde fuentes externas. Es idempotente por la pareja (source, external_id): reenviar el mismo pedido no crea un envío nuevo y responde 202.
  @POST('/integrations/shipments')
  Future<ReceiveShipmentAccepted> receiveShipment({
    @Body() required ReceiveShipmentRequest body,
  });

  /// Bulk-load orders from a CSV/Excel spreadsheet (idempotent per row).
  ///
  /// Carga masiva de pedidos desde una planilla (plantilla F0-SRC-03, CSV UTF-8). Cada fila se ingresa por la API única de recepción, idempotente por (source, external_id). Devuelve un reporte fila por fila (importados, duplicados, fallidos con su motivo); una fila mala no tumba a las demás, por eso responde 200 aunque haya filas fallidas.
  ///
  /// [file] - Spreadsheet file (CSV), up to 10 MB.
  @MultiPart()
  @POST('/integrations/shipments/import')
  Future<PostIntegrationsShipmentsImportResponse> importShipments({
    @Part(name: 'file') required File file,
  });

  /// Preview a (bulk) reschedule without changing anything.
  ///
  /// Admin y supervisor. Mismo body que POST /app/shipments/reschedule.
  @POST('/app/shipments/reschedule/preview')
  Future<PostAppShipmentsReschedulePreviewResponse> previewRescheduleShipments({
    @Body() required RescheduleShipmentsRequest body,
  });

  /// Reschedule orders — one, several, a whole truck or a whole city (admin only).
  ///
  /// Solo admin. Los pedidos cerrados (entregados, fallidos, anulados) se omiten y se informan en `skipped`. Una fecha bloqueada en el calendario se rechaza (code date_blocked). Un fallo en un pedido no corta el resto (queda en `failed`). Tope de 500 pedidos por operación (code scope_too_large). Queda auditado.
  @POST('/app/shipments/reschedule')
  Future<PostAppShipmentsRescheduleResponse> rescheduleShipments({
    @Body() required RescheduleShipmentsRequest body,
  });
}
