// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_channels_search_facets_response.dart';
import '../models/get_channels_search_products_response.dart';
import '../models/status8.dart';

part 'search_client.g.dart';

@RestApi()
abstract class SearchClient {
  factory SearchClient(Dio dio, {String? baseUrl}) = _SearchClient;

  /// Full-text search of catalog products.
  ///
  /// [q] - Search term (Postgres FTS, spanish). Omitted = browse by filters.
  ///
  /// [cursor] - Opaque keyset cursor for the next page.
  @GET('/channels/search/products')
  Future<GetChannelsSearchProductsResponse> searchProducts({
    @Query('status') Status8? status = Status8.published,
    @Query('limit') int? limit = 20,
    @Query('q') String? q,
    @Query('category_id') String? categoryId,
    @Query('cursor') String? cursor,
  });

  /// Category facets (counts) for the catalog
  @GET('/channels/search/facets')
  Future<GetChannelsSearchFacetsResponse> searchFacets({
    @Query('status') Status8? status = Status8.published,
  });
}
