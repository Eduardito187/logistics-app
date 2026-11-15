// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_product.dart';

part 'get_channels_catalog_products_id_response.g.dart';

@JsonSerializable()
class GetChannelsCatalogProductsIdResponse {
  const GetChannelsCatalogProductsIdResponse({required this.data});

  factory GetChannelsCatalogProductsIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsCatalogProductsIdResponseFromJson(json);

  final CommerceProduct data;

  Map<String, Object?> toJson() =>
      _$GetChannelsCatalogProductsIdResponseToJson(this);
}
