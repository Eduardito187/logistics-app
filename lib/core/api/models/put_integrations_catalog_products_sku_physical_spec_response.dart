// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'set_product_physical_spec_data.dart';

part 'put_integrations_catalog_products_sku_physical_spec_response.g.dart';

@JsonSerializable()
class PutIntegrationsCatalogProductsSkuPhysicalSpecResponse {
  const PutIntegrationsCatalogProductsSkuPhysicalSpecResponse({
    required this.data,
  });

  factory PutIntegrationsCatalogProductsSkuPhysicalSpecResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PutIntegrationsCatalogProductsSkuPhysicalSpecResponseFromJson(json);

  final SetProductPhysicalSpecData data;

  Map<String, Object?> toJson() =>
      _$PutIntegrationsCatalogProductsSkuPhysicalSpecResponseToJson(this);
}
