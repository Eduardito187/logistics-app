// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CursorMeta _$CursorMetaFromJson(Map<String, dynamic> json) => CursorMeta(
  count: (json['count'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  hasMore: json['has_more'] as bool,
  nextCursor: json['next_cursor'] as String?,
);

Map<String, dynamic> _$CursorMetaToJson(CursorMeta instance) =>
    <String, dynamic>{
      'count': instance.count,
      'per_page': instance.perPage,
      'has_more': instance.hasMore,
      'next_cursor': instance.nextCursor,
    };
