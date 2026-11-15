// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_catalog_product_availability_data.g.dart';

@JsonSerializable()
class GetCatalogProductAvailabilityData {
  const GetCatalogProductAvailabilityData({
    required this.canonicalSku,
    required this.available,
  });

  factory GetCatalogProductAvailabilityData.fromJson(
    Map<String, Object?> json,
  ) => _$GetCatalogProductAvailabilityDataFromJson(json);

  @JsonKey(name: 'canonical_sku')
  final String canonicalSku;
  final int available;

  Map<String, Object?> toJson() =>
      _$GetCatalogProductAvailabilityDataToJson(this);
}
