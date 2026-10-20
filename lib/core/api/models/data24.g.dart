// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data24.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data24 _$Data24FromJson(Map<String, dynamic> json) => Data24(
  id: json['id'] as String,
  status: OutboxStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data24ToJson(Data24 instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
};
