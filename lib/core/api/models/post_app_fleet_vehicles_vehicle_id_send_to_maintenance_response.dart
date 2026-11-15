// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_send_vehicle_to_maintenance_data.dart';

part 'post_app_fleet_vehicles_vehicle_id_send_to_maintenance_response.g.dart';

@JsonSerializable()
class PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse {
  const PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse({this.data});

  factory PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppFleetVehiclesVehicleIdSendToMaintenanceResponseFromJson(json);

  final FleetSendVehicleToMaintenanceData? data;

  Map<String, Object?> toJson() =>
      _$PostAppFleetVehiclesVehicleIdSendToMaintenanceResponseToJson(this);
}
