// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_live.dart';

part 'get_app_telemetry_fleet_live_response.g.dart';

@JsonSerializable()
class GetAppTelemetryFleetLiveResponse {
  const GetAppTelemetryFleetLiveResponse({required this.data});

  factory GetAppTelemetryFleetLiveResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryFleetLiveResponseFromJson(json);

  final List<VehicleLive> data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryFleetLiveResponseToJson(this);
}
