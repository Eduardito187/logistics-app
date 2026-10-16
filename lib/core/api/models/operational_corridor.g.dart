// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operational_corridor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperationalCorridor _$OperationalCorridorFromJson(Map<String, dynamic> json) =>
    OperationalCorridor(
      corridorType: CorridorType.fromJson(json['corridor_type'] as String),
      department: Department.fromJson(json['department'] as String),
      originNodeId: json['origin_node_id'] as String,
      originNodeCode: json['origin_node_code'] as String,
      originNodeName: json['origin_node_name'] as String,
      originNodeType: NodeType.fromJson(json['origin_node_type'] as String),
      destinationNodeId: json['destination_node_id'] as String?,
      destinationNodeCode: json['destination_node_code'] as String?,
      destinationNodeName: json['destination_node_name'] as String?,
      destinationNodeType: json['destination_node_type'] == null
          ? null
          : NodeType.fromJson(json['destination_node_type'] as String),
    );

Map<String, dynamic> _$OperationalCorridorToJson(
  OperationalCorridor instance,
) => <String, dynamic>{
  'corridor_type': instance.corridorType,
  'department': instance.department,
  'origin_node_id': instance.originNodeId,
  'origin_node_code': instance.originNodeCode,
  'origin_node_name': instance.originNodeName,
  'origin_node_type': instance.originNodeType,
  'destination_node_id': instance.destinationNodeId,
  'destination_node_code': instance.destinationNodeCode,
  'destination_node_name': instance.destinationNodeName,
  'destination_node_type': instance.destinationNodeType,
};
