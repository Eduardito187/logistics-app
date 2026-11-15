// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_product.dart';
import 'list_meta.dart';

part 'get_channels_catalog_products_response.g.dart';

@JsonSerializable()
class GetChannelsCatalogProductsResponse {
  const GetChannelsCatalogProductsResponse({required this.data, this.meta});

  factory GetChannelsCatalogProductsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsCatalogProductsResponseFromJson(json);

  final List<CommerceProduct> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetChannelsCatalogProductsResponseToJson(this);
}
