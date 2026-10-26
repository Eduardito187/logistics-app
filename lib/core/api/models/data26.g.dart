// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data26.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data26 _$Data26FromJson(Map<String, dynamic> json) => Data26(
  source: OrderSource.fromJson(json['source'] as String),
  externalId: json['external_id'] as String,
  status: Status9.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data26ToJson(Data26 instance) => <String, dynamic>{
  'source': instance.source,
  'external_id': instance.externalId,
  'status': instance.status,
};
