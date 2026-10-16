// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data23.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data23 _$Data23FromJson(Map<String, dynamic> json) => Data23(
  id: json['id'] as String,
  status: OutboxStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data23ToJson(Data23 instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
};
