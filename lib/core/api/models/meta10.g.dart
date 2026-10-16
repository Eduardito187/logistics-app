// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta10.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta10 _$Meta10FromJson(Map<String, dynamic> json) => Meta10(
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$Meta10ToJson(Meta10 instance) => <String, dynamic>{
  'date': instance.date?.toIso8601String(),
  'count': instance.count,
};
