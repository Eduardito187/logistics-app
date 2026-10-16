// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geofence.dart';

part 'get_app_telemetry_geofences_response.g.dart';

@JsonSerializable()
class GetAppTelemetryGeofencesResponse {
  const GetAppTelemetryGeofencesResponse({required this.data});

  factory GetAppTelemetryGeofencesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryGeofencesResponseFromJson(json);

  final List<Geofence> data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryGeofencesResponseToJson(this);
}
