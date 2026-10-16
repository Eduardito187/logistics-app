// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_unit.dart';

part 'capacity_bucket.g.dart';

@JsonSerializable()
class CapacityBucket {
  const CapacityBucket({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.unit,
    required this.total,
    required this.used,
    required this.available,
    required this.full,
    this.nodeId,
    this.zoneId,
    this.municipalityId,
  });

  factory CapacityBucket.fromJson(Map<String, Object?> json) =>
      _$CapacityBucketFromJson(json);

  final String id;
  @JsonKey(name: 'node_id')
  final String? nodeId;
  @JsonKey(name: 'zone_id')
  final String? zoneId;

  /// Municipality (coverage area) the bucket belongs to, when its scope is a municipality.
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final DateTime date;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final CapacityUnit unit;
  final double total;
  final double used;
  final double available;
  final bool full;

  Map<String, Object?> toJson() => _$CapacityBucketToJson(this);
}
