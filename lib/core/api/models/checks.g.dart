// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Checks _$ChecksFromJson(Map<String, dynamic> json) => Checks(
  database: json['database'] as bool,
  schema: json['schema'] as bool,
  cache: json['cache'] as bool,
);

Map<String, dynamic> _$ChecksToJson(Checks instance) => <String, dynamic>{
  'database': instance.database,
  'schema': instance.schema,
  'cache': instance.cache,
};
