// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'batch_set_product_physical_specs_data.dart';

part 'post_integrations_catalog_products_physical_specs_response.g.dart';

@JsonSerializable()
class PostIntegrationsCatalogProductsPhysicalSpecsResponse {
  const PostIntegrationsCatalogProductsPhysicalSpecsResponse({
    required this.data,
  });

  factory PostIntegrationsCatalogProductsPhysicalSpecsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsCatalogProductsPhysicalSpecsResponseFromJson(json);

  final BatchSetProductPhysicalSpecsData data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsCatalogProductsPhysicalSpecsResponseToJson(this);
}
