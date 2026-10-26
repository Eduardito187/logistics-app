// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/seller_portal_asn_collection.dart';
import '../models/seller_portal_settlement_collection.dart';
import '../models/seller_portal_stock_collection.dart';

part 'seller_portal_client.g.dart';

@RestApi()
abstract class SellerPortalClient {
  factory SellerPortalClient(Dio dio, {String? baseUrl}) = _SellerPortalClient;

  /// List the authenticated seller's ASNs.
  ///
  /// ASNs (inbound) del seller autenticado. El sellerId se resuelve del token de integración, así que un.
  /// seller solo puede leer lo suyo.
  @GET('/integrations/seller-portal/asns')
  Future<SellerPortalAsnCollection> sellerPortalListAsns();

  /// Get the authenticated seller's on-hand stock.
  ///
  /// Stock on-hand (inventory) del seller autenticado. El sellerId se resuelve del token de integración.
  @GET('/integrations/seller-portal/stock')
  Future<SellerPortalStockCollection> sellerPortalGetStock();

  /// List the authenticated seller's settlements.
  ///
  /// Liquidaciones (settlement) del seller autenticado. El sellerId se resuelve del token de integración.
  @GET('/integrations/seller-portal/settlements')
  Future<SellerPortalSettlementCollection> sellerPortalListSettlements();
}
