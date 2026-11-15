// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integrations_catalog_products_physical_specs_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationsCatalogProductsPhysicalSpecsRequestBody
_$IntegrationsCatalogProductsPhysicalSpecsRequestBodyFromJson(
  Map<String, dynamic> json,
) => IntegrationsCatalogProductsPhysicalSpecsRequestBody(
  items: (json['items'] as List<dynamic>)
      .map((e) => Items.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic>
_$IntegrationsCatalogProductsPhysicalSpecsRequestBodyToJson(
  IntegrationsCatalogProductsPhysicalSpecsRequestBody instance,
) => <String, dynamic>{'items': instance.items};
