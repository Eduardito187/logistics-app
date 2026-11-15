// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_channels_catalog_products_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelsCatalogProductsResponse _$GetChannelsCatalogProductsResponseFromJson(
  Map<String, dynamic> json,
) => GetChannelsCatalogProductsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CommerceProduct.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetChannelsCatalogProductsResponseToJson(
  GetChannelsCatalogProductsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
