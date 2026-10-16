// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'define_leg_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefineLegRequest _$DefineLegRequestFromJson(Map<String, dynamic> json) =>
    DefineLegRequest(
      fromNodeId: json['from_node_id'] as String,
      toNodeId: json['to_node_id'] as String,
      corridorType: CorridorType.fromJson(json['corridor_type'] as String),
    );

Map<String, dynamic> _$DefineLegRequestToJson(DefineLegRequest instance) =>
    <String, dynamic>{
      'from_node_id': instance.fromNodeId,
      'to_node_id': instance.toNodeId,
      'corridor_type': instance.corridorType,
    };
