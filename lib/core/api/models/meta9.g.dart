// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta9.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta9 _$Meta9FromJson(Map<String, dynamic> json) => Meta9(
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
);

Map<String, dynamic> _$Meta9ToJson(Meta9 instance) => <String, dynamic>{
  'total': instance.total,
  'page': instance.page,
  'per_page': instance.perPage,
  'last_page': instance.lastPage,
};
