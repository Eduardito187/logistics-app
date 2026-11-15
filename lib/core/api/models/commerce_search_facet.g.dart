// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_search_facet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceSearchFacet _$CommerceSearchFacetFromJson(Map<String, dynamic> json) =>
    CommerceSearchFacet(
      count: (json['count'] as num).toInt(),
      categoryId: json['category_id'] as String?,
    );

Map<String, dynamic> _$CommerceSearchFacetToJson(
  CommerceSearchFacet instance,
) => <String, dynamic>{
  'category_id': instance.categoryId,
  'count': instance.count,
};
