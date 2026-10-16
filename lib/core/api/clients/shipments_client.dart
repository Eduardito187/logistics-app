// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_app_shipments_low_confidence_addresses_response.dart';
import '../models/get_app_shipments_response.dart';
import '../models/get_app_shipments_shipment_response.dart';
import '../models/order_source.dart';
import '../models/post_app_shipments_shipment_geocode_response.dart';
import '../models/post_integrations_shipments_import_response.dart';
import '../models/receive_shipment_accepted.dart';
import '../models/receive_shipment_request.dart';
import '../models/shipment_status.dart';

part 'shipments_client.g.dart';

@RestApi()
abstract class ShipmentsClient {
  factory ShipmentsClient(Dio dio, {String? baseUrl}) = _ShipmentsClient;

  /// List received orders, optionally filtered by status and source.
  ///
  /// Supports optional offset or cursor pagination (E-02). Without any pagination parameter the full collection is returned unchanged; with `page`/`per_page` or `cursor` the response is sliced and a `meta` object is added. Cursor pagination is preferred for this growing collection.
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
    @Query('status') ShipmentStatus? status,
    @Query('source') OrderSource? source,
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
}
