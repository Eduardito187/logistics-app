// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'items.dart';

part 'integrations_catalog_products_physical_specs_request_body.g.dart';

@JsonSerializable()
class IntegrationsCatalogProductsPhysicalSpecsRequestBody {
  const IntegrationsCatalogProductsPhysicalSpecsRequestBody({
    required this.items,
  });

  factory IntegrationsCatalogProductsPhysicalSpecsRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$IntegrationsCatalogProductsPhysicalSpecsRequestBodyFromJson(json);

  final List<Items> items;

  Map<String, Object?> toJson() =>
      _$IntegrationsCatalogProductsPhysicalSpecsRequestBodyToJson(this);
}
