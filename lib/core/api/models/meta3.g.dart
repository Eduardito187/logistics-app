// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta3 _$Meta3FromJson(Map<String, dynamic> json) => Meta3(
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$Meta3ToJson(Meta3 instance) => <String, dynamic>{
  'date': instance.date?.toIso8601String(),
  'count': instance.count,
};
