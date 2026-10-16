// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta15.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta15 _$Meta15FromJson(Map<String, dynamic> json) => Meta15(
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
);

Map<String, dynamic> _$Meta15ToJson(Meta15 instance) => <String, dynamic>{
  'total': instance.total,
  'page': instance.page,
  'per_page': instance.perPage,
  'last_page': instance.lastPage,
};
