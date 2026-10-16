// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data6.dart';

part 'patch_app_fleet_vehicles_vehicle_id_status_response.g.dart';

@JsonSerializable()
class PatchAppFleetVehiclesVehicleIdStatusResponse {
  const PatchAppFleetVehiclesVehicleIdStatusResponse({this.data});

  factory PatchAppFleetVehiclesVehicleIdStatusResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PatchAppFleetVehiclesVehicleIdStatusResponseFromJson(json);

  final Data6? data;

  Map<String, Object?> toJson() =>
      _$PatchAppFleetVehiclesVehicleIdStatusResponseToJson(this);
}
