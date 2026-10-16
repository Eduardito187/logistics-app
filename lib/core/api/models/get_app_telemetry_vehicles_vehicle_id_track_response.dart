// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_ping.dart';

part 'get_app_telemetry_vehicles_vehicle_id_track_response.g.dart';

@JsonSerializable()
class GetAppTelemetryVehiclesVehicleIdTrackResponse {
  const GetAppTelemetryVehiclesVehicleIdTrackResponse({required this.data});

  factory GetAppTelemetryVehiclesVehicleIdTrackResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryVehiclesVehicleIdTrackResponseFromJson(json);

  final List<VehiclePing> data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryVehiclesVehicleIdTrackResponseToJson(this);
}
