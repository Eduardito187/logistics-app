// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data25.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data25 _$Data25FromJson(Map<String, dynamic> json) => Data25(
  source: OrderSource.fromJson(json['source'] as String),
  externalId: json['external_id'] as String,
  status: Status7.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data25ToJson(Data25 instance) => <String, dynamic>{
  'source': instance.source,
  'external_id': instance.externalId,
  'status': instance.status,
};
