// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_catalog_product_availability_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetCatalogProductAvailabilityData _$GetCatalogProductAvailabilityDataFromJson(
  Map<String, dynamic> json,
) => GetCatalogProductAvailabilityData(
  canonicalSku: json['canonical_sku'] as String,
  available: (json['available'] as num).toInt(),
);

Map<String, dynamic> _$GetCatalogProductAvailabilityDataToJson(
  GetCatalogProductAvailabilityData instance,
) => <String, dynamic>{
  'canonical_sku': instance.canonicalSku,
  'available': instance.available,
};
