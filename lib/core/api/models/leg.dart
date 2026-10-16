// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'corridor_type.dart';

part 'leg.g.dart';

@JsonSerializable()
class Leg {
  const Leg({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.corridorType,
  });

  factory Leg.fromJson(Map<String, Object?> json) => _$LegFromJson(json);

  final String id;
  @JsonKey(name: 'from_node_id')
  final String fromNodeId;
  @JsonKey(name: 'to_node_id')
  final String toNodeId;
  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;

  Map<String, Object?> toJson() => _$LegToJson(this);
}
