// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_channels_catalog_categories_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelsCatalogCategoriesResponse
_$GetChannelsCatalogCategoriesResponseFromJson(Map<String, dynamic> json) =>
    GetChannelsCatalogCategoriesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CommerceCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetChannelsCatalogCategoriesResponseToJson(
  GetChannelsCatalogCategoriesResponse instance,
) => <String, dynamic>{'data': instance.data};
