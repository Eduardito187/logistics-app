// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geo_point.dart';

part 'app_telemetry_geofences_geofence_id_redraw_request_body.g.dart';

@JsonSerializable()
class AppTelemetryGeofencesGeofenceIdRedrawRequestBody {
  const AppTelemetryGeofencesGeofenceIdRedrawRequestBody({
    required this.polygon,
  });

  factory AppTelemetryGeofencesGeofenceIdRedrawRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppTelemetryGeofencesGeofenceIdRedrawRequestBodyFromJson(json);

  final List<GeoPoint> polygon;

  Map<String, Object?> toJson() =>
      _$AppTelemetryGeofencesGeofenceIdRedrawRequestBodyToJson(this);
}
