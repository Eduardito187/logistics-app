// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) => Data(
  kind: Kind.fromJson(json['kind'] as String),
  disk: json['disk'] as String,
  path: json['path'] as String,
  url: json['url'] as String?,
);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  'kind': instance.kind,
  'disk': instance.disk,
  'path': instance.path,
  'url': instance.url,
};
