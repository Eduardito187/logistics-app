// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Summary _$SummaryFromJson(Map<String, dynamic> json) => Summary(
  updated: (json['updated'] as num?)?.toInt(),
  notFound: (json['not_found'] as num?)?.toInt(),
  invalid: (json['invalid'] as num?)?.toInt(),
);

Map<String, dynamic> _$SummaryToJson(Summary instance) => <String, dynamic>{
  'updated': instance.updated,
  'not_found': instance.notFound,
  'invalid': instance.invalid,
};
