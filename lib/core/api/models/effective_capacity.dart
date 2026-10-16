// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_unit.dart';
import 'effective_capacity_source.dart';

part 'effective_capacity.g.dart';

/// Effective capacity for a key. `source` tells where the figures come from: `bucket` (an explicit bucket exists), `rule` (no bucket, but the configurable rules give a default total with zero used) or `none` (no bucket and no rule: capacity unknown, reported as zero).
@JsonSerializable()
class EffectiveCapacity {
  const EffectiveCapacity({
    required this.date,
    required this.timeSlot,
    required this.unit,
    required this.total,
    required this.used,
    required this.available,
    required this.full,
    required this.source,
    this.bucketId,
    this.nodeId,
    this.zoneId,
    this.municipalityId,
  });

  factory EffectiveCapacity.fromJson(Map<String, Object?> json) =>
      _$EffectiveCapacityFromJson(json);

  @JsonKey(name: 'bucket_id')
  final String? bucketId;
  @JsonKey(name: 'node_id')
  final String? nodeId;
  @JsonKey(name: 'zone_id')
  final String? zoneId;

  /// Municipality (coverage area) the key belongs to, when its scope is a municipality.
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
  final EffectiveCapacitySource source;

  Map<String, Object?> toJson() => _$EffectiveCapacityToJson(this);
}
