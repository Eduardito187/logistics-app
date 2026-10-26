// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/register_seller_request.dart';
import '../models/seller_collection.dart';
import '../models/seller_envelope.dart';
import '../models/set_settlement_terms_request.dart';
import '../models/status8.dart';
import '../models/upsert_seller_sku_request.dart';

part 'sellers_client.g.dart';

@RestApi()
abstract class SellersClient {
  factory SellersClient(Dio dio, {String? baseUrl}) = _SellersClient;

  /// Register a seller.
  ///
  /// Da de alta un seller (proveedor de marketplace). El id lo genera el dominio; la respuesta es un acuse 202.
  @POST('/integrations/sellers')
  Future<AcceptedEnvelope> registerSeller({
    @Body() required RegisterSellerRequest body,
  });

  /// List sellers.
  ///
  /// [status] - Optional filter by seller status.
  @GET('/integrations/sellers')
  Future<SellerCollection> listSellers({@Query('status') Status8? status});

  /// Get a seller
  @GET('/integrations/sellers/{sellerId}')
  Future<SellerEnvelope> getSeller({
    @Path('sellerId') required String sellerId,
  });

  /// Set a seller's settlement terms
  @PUT('/integrations/sellers/{sellerId}/settlement-terms')
  Future<AcceptedEnvelope> setSellerSettlementTerms({
    @Path('sellerId') required String sellerId,
    @Body() required SetSettlementTermsRequest body,
  });

  /// Upsert a seller SKU
  @POST('/integrations/sellers/{sellerId}/skus')
  Future<AcceptedEnvelope> upsertSellerSku({
    @Path('sellerId') required String sellerId,
    @Body() required UpsertSellerSkuRequest body,
  });
}
