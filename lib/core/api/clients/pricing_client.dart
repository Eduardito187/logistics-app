// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/channel_option.dart';
import '../models/commerce_create_price_list_request.dart';
import '../models/commerce_set_price_request.dart';
import '../models/get_channels_pricing_price_response.dart';
import '../models/get_channels_pricing_prices_response.dart';
import '../models/get_integrations_pricing_price_lists_response.dart';
import '../models/post_integrations_pricing_price_lists_id_activate_response.dart';
import '../models/post_integrations_pricing_price_lists_id_archive_response.dart';
import '../models/post_integrations_pricing_price_lists_id_prices_response.dart';
import '../models/post_integrations_pricing_price_lists_response.dart';

part 'pricing_client.g.dart';

@RestApi()
abstract class PricingClient {
  factory PricingClient(Dio dio, {String? baseUrl}) = _PricingClient;

  /// Resolve the current price of a SKU for a sales channel.
  ///
  /// [channel] - Sales channel; defaults to retail (B2C storefront).
  @GET('/channels/pricing/price')
  Future<GetChannelsPricingPriceResponse> getPrice({
    @Query('sku') required String sku,
    @Query('channel') ChannelOption? channel,
  });

  /// List the prices of a price list.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/channels/pricing/prices')
  Future<GetChannelsPricingPricesResponse> listPrices({
    @Query('price_list_id') required String priceListId,
    @Query('cursor') String? cursor,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// List price lists.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/integrations/pricing/price-lists')
  Future<GetIntegrationsPricingPriceListsResponse> listPriceLists({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('channel') ChannelOption? channel,
    @Query('cursor') String? cursor,
  });

  /// Create a price list
  @POST('/integrations/pricing/price-lists')
  Future<PostIntegrationsPricingPriceListsResponse> createPriceList({
    @Body() required CommerceCreatePriceListRequest body,
  });

  /// Set the price of a SKU in a price list
  @POST('/integrations/pricing/price-lists/{id}/prices')
  Future<PostIntegrationsPricingPriceListsIdPricesResponse> setPrice({
    @Path('id') required String id,
    @Body() required CommerceSetPriceRequest body,
  });

  /// Activate a price list
  @POST('/integrations/pricing/price-lists/{id}/activate')
  Future<PostIntegrationsPricingPriceListsIdActivateResponse>
  activatePriceList({@Path('id') required String id});

  /// Archive a price list
  @POST('/integrations/pricing/price-lists/{id}/archive')
  Future<PostIntegrationsPricingPriceListsIdArchiveResponse> archivePriceList({
    @Path('id') required String id,
  });
}
