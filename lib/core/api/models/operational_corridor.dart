// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'corridor_type.dart';
import 'department.dart';
import 'node_type.dart';

part 'operational_corridor.g.dart';

/// An operational corridor in a department: the insumo planning/promise use to know what can.
/// leave (and enter) that department. Inter-node corridors (cd_to_cd, cd_to_store,.
/// store_to_store, store_to_cd) carry an origin and a destination node; terminal corridors.
/// (cd_to_customer, store_pickup) end at the customer, so the destination fields are null.
///
@JsonSerializable()
class OperationalCorridor {
  const OperationalCorridor({
    required this.corridorType,
    required this.department,
    required this.originNodeId,
    required this.originNodeCode,
    required this.originNodeName,
    required this.originNodeType,
    required this.destinationNodeId,
    required this.destinationNodeCode,
    required this.destinationNodeName,
    required this.destinationNodeType,
  });

  factory OperationalCorridor.fromJson(Map<String, Object?> json) =>
      _$OperationalCorridorFromJson(json);

  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;
  final Department department;
  @JsonKey(name: 'origin_node_id')
  final String originNodeId;
  @JsonKey(name: 'origin_node_code')
  final String originNodeCode;
  @JsonKey(name: 'origin_node_name')
  final String originNodeName;
  @JsonKey(name: 'origin_node_type')
  final NodeType originNodeType;
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  @JsonKey(name: 'destination_node_code')
  final String? destinationNodeCode;
  @JsonKey(name: 'destination_node_name')
  final String? destinationNodeName;
  @JsonKey(name: 'destination_node_type')
  final NodeType? destinationNodeType;

  Map<String, Object?> toJson() => _$OperationalCorridorToJson(this);
}
