// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'trip_capacity.g.dart';

/// Load of the selected shipments against the truck capacity. Only in GET /app/plans/candidates.
@JsonSerializable()
class TripCapacity {
  const TripCapacity({
    required this.usedUnits,
    required this.usedKg,
    required this.usedM3,
    this.maxUnits,
    this.maxKg,
    this.maxM3,
  });

  factory TripCapacity.fromJson(Map<String, Object?> json) =>
      _$TripCapacityFromJson(json);

  @JsonKey(name: 'used_units')
  final int usedUnits;

  /// Always null today; the fleet defines no unit limit.
  @JsonKey(name: 'max_units')
  final int? maxUnits;
  @JsonKey(name: 'used_kg')
  final double usedKg;
  @JsonKey(name: 'max_kg')
  final double? maxKg;
  @JsonKey(name: 'used_m3')
  final double usedM3;
  @JsonKey(name: 'max_m3')
  final double? maxM3;

  Map<String, Object?> toJson() => _$TripCapacityToJson(this);
}
