// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_channels_catalog_categories_response.dart';
import '../models/get_channels_catalog_products_id_availability_response.dart';
import '../models/get_channels_catalog_products_id_response.dart';
import '../models/get_channels_catalog_products_response.dart';
import '../models/integrations_catalog_products_physical_specs_request_body.dart';
import '../models/post_integrations_catalog_products_physical_specs_response.dart';
import '../models/product_physical_spec_input.dart';
import '../models/put_integrations_catalog_products_sku_physical_spec_response.dart';
import '../models/status8.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  /// Set the measurements of one product (weight and dimensions) by SKU
  @PUT('/integrations/catalog/products/{sku}/physical-spec')
  Future<PutIntegrationsCatalogProductsSkuPhysicalSpecResponse>
  setProductPhysicalSpec({
    @Path('sku') required String sku,
    @Body() required ProductPhysicalSpecInput body,
  });

  /// Set the measurements of many products in one request (per-item result)
  @POST('/integrations/catalog/products/physical-specs')
  Future<PostIntegrationsCatalogProductsPhysicalSpecsResponse>
  batchSetProductPhysicalSpecs({
    @Body() required IntegrationsCatalogProductsPhysicalSpecsRequestBody body,
  });

  /// List catalog products (storefront browse).
  ///
  /// Returns the catalog products for the storefront. Optional filter by publication `status` and optional additive pagination (E-02): without any pagination parameter the full collection is returned with no `meta`.
  ///
  /// [status] - Filter by publication status.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/channels/catalog/products')
  Future<GetChannelsCatalogProductsResponse> listCatalogProducts({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') Status8? status,
    @Query('cursor') String? cursor,
  });

  /// Get a catalog product by id.
  ///
  /// [id] - Product id.
  @GET('/channels/catalog/products/{id}')
  Future<GetChannelsCatalogProductsIdResponse> getCatalogProduct({
    @Path('id') required String id,
  });

  /// List catalog categories
  @GET('/channels/catalog/categories')
  Future<GetChannelsCatalogCategoriesResponse> listCatalogCategories();

  /// Available-to-promise quantity of a product (read from inventory)
  @GET('/channels/catalog/products/{id}/availability')
  Future<GetChannelsCatalogProductsIdAvailabilityResponse>
  getCatalogProductAvailability({@Path('id') required String id});
}
