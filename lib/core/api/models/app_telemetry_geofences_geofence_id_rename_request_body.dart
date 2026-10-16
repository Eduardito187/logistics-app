// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_telemetry_geofences_geofence_id_rename_request_body.g.dart';

@JsonSerializable()
class AppTelemetryGeofencesGeofenceIdRenameRequestBody {
  const AppTelemetryGeofencesGeofenceIdRenameRequestBody({required this.name});

  factory AppTelemetryGeofencesGeofenceIdRenameRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppTelemetryGeofencesGeofenceIdRenameRequestBodyFromJson(json);

  final String name;

  Map<String, Object?> toJson() =>
      _$AppTelemetryGeofencesGeofenceIdRenameRequestBodyToJson(this);
}
