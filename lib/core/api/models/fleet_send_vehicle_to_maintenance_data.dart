// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_route_outcome.dart';

part 'fleet_send_vehicle_to_maintenance_data.g.dart';

@JsonSerializable()
class FleetSendVehicleToMaintenanceData {
  const FleetSendVehicleToMaintenanceData({
    this.status,
    this.vehicleId,
    this.newStatus,
    this.route,
  });

  factory FleetSendVehicleToMaintenanceData.fromJson(
    Map<String, Object?> json,
  ) => _$FleetSendVehicleToMaintenanceDataFromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'new_status')
  final String? newStatus;
  final MaintenanceRouteOutcome? route;

  Map<String, Object?> toJson() =>
      _$FleetSendVehicleToMaintenanceDataToJson(this);
}
