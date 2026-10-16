// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Node _$NodeFromJson(Map<String, dynamic> json) => Node(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  type: NodeType.fromJson(json['type'] as String),
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  status: NodeStatus.fromJson(json['status'] as String),
  department: json['department'] == null
      ? null
      : Department.fromJson(json['department'] as String),
);

Map<String, dynamic> _$NodeToJson(Node instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'type': instance.type,
  'lat': instance.lat,
  'lng': instance.lng,
  'status': instance.status,
  'department': instance.department,
};
