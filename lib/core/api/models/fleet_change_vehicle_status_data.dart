// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_status.dart';

part 'fleet_change_vehicle_status_data.g.dart';

@JsonSerializable()
class FleetChangeVehicleStatusData {
  const FleetChangeVehicleStatusData({
    this.status,
    this.vehicleId,
    this.newStatus,
  });

  factory FleetChangeVehicleStatusData.fromJson(Map<String, Object?> json) =>
      _$FleetChangeVehicleStatusDataFromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'new_status')
  final VehicleStatus? newStatus;

  Map<String, Object?> toJson() => _$FleetChangeVehicleStatusDataToJson(this);
}
