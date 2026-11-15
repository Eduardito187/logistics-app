// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'get_catalog_product_availability_data.dart';

part 'get_channels_catalog_products_id_availability_response.g.dart';

@JsonSerializable()
class GetChannelsCatalogProductsIdAvailabilityResponse {
  const GetChannelsCatalogProductsIdAvailabilityResponse({required this.data});

  factory GetChannelsCatalogProductsIdAvailabilityResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsCatalogProductsIdAvailabilityResponseFromJson(json);

  final GetCatalogProductAvailabilityData data;

  Map<String, Object?> toJson() =>
      _$GetChannelsCatalogProductsIdAvailabilityResponseToJson(this);
}
