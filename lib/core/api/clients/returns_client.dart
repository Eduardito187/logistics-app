// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/disposition_return_request.dart';
import '../models/initiate_return_request.dart';
import '../models/return_order_collection.dart';
import '../models/return_order_envelope.dart';
import '../models/return_order_status.dart';

part 'returns_client.g.dart';

@RestApi()
abstract class ReturnsClient {
  factory ReturnsClient(Dio dio, {String? baseUrl}) = _ReturnsClient;

  /// Initiate a return.
  ///
  /// Inicia una devolución (logística inversa). El id lo genera el dominio; la respuesta es un acuse 202.
  /// (la escritura confirma vía outbox).
  @POST('/integrations/returns')
  Future<AcceptedEnvelope> initiateReturn({
    @Body() required InitiateReturnRequest body,
  });

  /// List returns.
  ///
  /// [sellerId] - Optional filter by owning seller.
  ///
  /// [status] - Optional filter by return status.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/integrations/returns')
  Future<ReturnOrderCollection> listReturns({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('seller_id') String? sellerId,
    @Query('status') ReturnOrderStatus? status,
    @Query('cursor') String? cursor,
  });

  /// Get a return
  @GET('/integrations/returns/{returnId}')
  Future<ReturnOrderEnvelope> getReturn({
    @Path('returnId') required String returnId,
  });

  /// Receive a return.
  ///
  /// Registra la recepción física de una devolución. Respuesta de acuse 202.
  @POST('/integrations/returns/{returnId}/receive')
  Future<AcceptedEnvelope> receiveReturn({
    @Path('returnId') required String returnId,
  });

  /// Disposition a return.
  ///
  /// Decide la disposición de una devolución recibida (restock / return_to_seller / scrap). Respuesta de.
  /// acuse 202.
  @POST('/integrations/returns/{returnId}/disposition')
  Future<AcceptedEnvelope> dispositionReturn({
    @Path('returnId') required String returnId,
    @Body() required DispositionReturnRequest body,
  });
}
