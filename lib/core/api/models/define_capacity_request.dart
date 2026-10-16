// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_unit.dart';

part 'define_capacity_request.g.dart';

/// Exactly one of node_id/zone_id must be present.
@JsonSerializable()
class DefineCapacityRequest {
  const DefineCapacityRequest({
    required this.date,
    required this.timeSlot,
    required this.unit,
    required this.total,
    this.nodeId,
    this.zoneId,
  });

  factory DefineCapacityRequest.fromJson(Map<String, Object?> json) =>
      _$DefineCapacityRequestFromJson(json);

  @JsonKey(name: 'node_id')
  final String? nodeId;
  @JsonKey(name: 'zone_id')
  final String? zoneId;
  final DateTime date;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final CapacityUnit unit;
  final double total;

  Map<String, Object?> toJson() => _$DefineCapacityRequestToJson(this);
}
