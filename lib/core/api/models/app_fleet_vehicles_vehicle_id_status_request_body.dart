// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_status.dart';

part 'app_fleet_vehicles_vehicle_id_status_request_body.g.dart';

@JsonSerializable()
class AppFleetVehiclesVehicleIdStatusRequestBody {
  const AppFleetVehiclesVehicleIdStatusRequestBody({required this.status});

  factory AppFleetVehiclesVehicleIdStatusRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppFleetVehiclesVehicleIdStatusRequestBodyFromJson(json);

  final VehicleStatus status;

  Map<String, Object?> toJson() =>
      _$AppFleetVehiclesVehicleIdStatusRequestBodyToJson(this);
}
