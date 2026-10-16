// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'corridor_type.dart';

part 'define_leg_request.g.dart';

@JsonSerializable()
class DefineLegRequest {
  const DefineLegRequest({
    required this.fromNodeId,
    required this.toNodeId,
    required this.corridorType,
  });

  factory DefineLegRequest.fromJson(Map<String, Object?> json) =>
      _$DefineLegRequestFromJson(json);

  @JsonKey(name: 'from_node_id')
  final String fromNodeId;
  @JsonKey(name: 'to_node_id')
  final String toNodeId;
  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;

  Map<String, Object?> toJson() => _$DefineLegRequestToJson(this);
}
