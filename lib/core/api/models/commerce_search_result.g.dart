// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceSearchResult _$CommerceSearchResultFromJson(
  Map<String, dynamic> json,
) => CommerceSearchResult(
  items: (json['items'] as List<dynamic>)
      .map((e) => CommerceSearchItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  total: (json['total'] as num?)?.toInt(),
);

Map<String, dynamic> _$CommerceSearchResultToJson(
  CommerceSearchResult instance,
) => <String, dynamic>{
  'items': instance.items,
  'next_cursor': instance.nextCursor,
  'total': instance.total,
};
