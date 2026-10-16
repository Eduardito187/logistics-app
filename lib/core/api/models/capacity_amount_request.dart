// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_unit.dart';

part 'capacity_amount_request.g.dart';

/// Exactly one of node_id/zone_id must be present.
@JsonSerializable()
class CapacityAmountRequest {
  const CapacityAmountRequest({
    required this.date,
    required this.timeSlot,
    required this.unit,
    required this.amount,
    this.nodeId,
    this.zoneId,
  });

  factory CapacityAmountRequest.fromJson(Map<String, Object?> json) =>
      _$CapacityAmountRequestFromJson(json);

  @JsonKey(name: 'node_id')
  final String? nodeId;
  @JsonKey(name: 'zone_id')
  final String? zoneId;
  final DateTime date;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final CapacityUnit unit;
  final double amount;

  Map<String, Object?> toJson() => _$CapacityAmountRequestToJson(this);
}
