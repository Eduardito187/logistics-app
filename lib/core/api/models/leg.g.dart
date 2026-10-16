// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Leg _$LegFromJson(Map<String, dynamic> json) => Leg(
  id: json['id'] as String,
  fromNodeId: json['from_node_id'] as String,
  toNodeId: json['to_node_id'] as String,
  corridorType: CorridorType.fromJson(json['corridor_type'] as String),
);

Map<String, dynamic> _$LegToJson(Leg instance) => <String, dynamic>{
  'id': instance.id,
  'from_node_id': instance.fromNodeId,
  'to_node_id': instance.toNodeId,
  'corridor_type': instance.corridorType,
};
