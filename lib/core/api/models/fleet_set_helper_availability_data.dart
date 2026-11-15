// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_set_helper_availability_data.g.dart';

@JsonSerializable()
class FleetSetHelperAvailabilityData {
  const FleetSetHelperAvailabilityData({
    this.status,
    this.helperId,
    this.active,
  });

  factory FleetSetHelperAvailabilityData.fromJson(Map<String, Object?> json) =>
      _$FleetSetHelperAvailabilityDataFromJson(json);

  final String? status;
  @JsonKey(name: 'helper_id')
  final String? helperId;
  final bool? active;

  Map<String, Object?> toJson() => _$FleetSetHelperAvailabilityDataToJson(this);
}
