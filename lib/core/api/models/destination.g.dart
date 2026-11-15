// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Destination _$DestinationFromJson(Map<String, dynamic> json) => Destination(
  type: json['type'] == null ? null : Type4.fromJson(json['type'] as String),
  name: json['name'] as String?,
  nodeCode: json['node_code'] as String?,
  nodeId: json['node_id'] as String?,
);

Map<String, dynamic> _$DestinationToJson(Destination instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'node_code': instance.nodeCode,
      'node_id': instance.nodeId,
    };
