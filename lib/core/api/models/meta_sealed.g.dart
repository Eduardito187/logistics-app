// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta_sealed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$MetaSealedToJson(MetaSealed instance) =>
    <String, dynamic>{};

MetaSealedVariant1 _$MetaSealedVariant1FromJson(Map<String, dynamic> json) =>
    MetaSealedVariant1(count: (json['count'] as num).toInt());

Map<String, dynamic> _$MetaSealedVariant1ToJson(MetaSealedVariant1 instance) =>
    <String, dynamic>{'count': instance.count};

MetaSealedPaginationMeta _$MetaSealedPaginationMetaFromJson(
  Map<String, dynamic> json,
) => MetaSealedPaginationMeta(
  count: (json['count'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  perPage: (json['perPage'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  nextPage: (json['nextPage'] as num?)?.toInt(),
  prevPage: (json['prevPage'] as num?)?.toInt(),
);

Map<String, dynamic> _$MetaSealedPaginationMetaToJson(
  MetaSealedPaginationMeta instance,
) => <String, dynamic>{
  'count': instance.count,
  'page': instance.page,
  'perPage': instance.perPage,
  'total': instance.total,
  'totalPages': instance.totalPages,
  'nextPage': instance.nextPage,
  'prevPage': instance.prevPage,
};

MetaSealedCursorMeta _$MetaSealedCursorMetaFromJson(
  Map<String, dynamic> json,
) => MetaSealedCursorMeta(
  count: (json['count'] as num).toInt(),
  perPage: (json['perPage'] as num).toInt(),
  hasMore: json['hasMore'] as bool,
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$MetaSealedCursorMetaToJson(
  MetaSealedCursorMeta instance,
) => <String, dynamic>{
  'count': instance.count,
  'perPage': instance.perPage,
  'hasMore': instance.hasMore,
  'nextCursor': instance.nextCursor,
};
