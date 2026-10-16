// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta _$MetaFromJson(Map<String, dynamic> json) => Meta(
  date: DateTime.parse(json['date'] as String),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$MetaToJson(Meta instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'count': instance.count,
};
