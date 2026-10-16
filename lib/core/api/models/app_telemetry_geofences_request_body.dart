// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geofence_type.dart';
import 'geo_point.dart';

part 'app_telemetry_geofences_request_body.g.dart';

@JsonSerializable()
class AppTelemetryGeofencesRequestBody {
  const AppTelemetryGeofencesRequestBody({
    required this.name,
    required this.type,
    required this.polygon,
    this.nodeRef,
  });

  factory AppTelemetryGeofencesRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppTelemetryGeofencesRequestBodyFromJson(json);

  final String name;
  final GeofenceType type;
  final List<GeoPoint> polygon;
  @JsonKey(name: 'node_ref')
  final String? nodeRef;

  Map<String, Object?> toJson() =>
      _$AppTelemetryGeofencesRequestBodyToJson(this);
}
