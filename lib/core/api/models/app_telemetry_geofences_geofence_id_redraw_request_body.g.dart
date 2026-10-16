// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_telemetry_geofences_geofence_id_redraw_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppTelemetryGeofencesGeofenceIdRedrawRequestBody
_$AppTelemetryGeofencesGeofenceIdRedrawRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppTelemetryGeofencesGeofenceIdRedrawRequestBody(
  polygon: (json['polygon'] as List<dynamic>)
      .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AppTelemetryGeofencesGeofenceIdRedrawRequestBodyToJson(
  AppTelemetryGeofencesGeofenceIdRedrawRequestBody instance,
) => <String, dynamic>{'polygon': instance.polygon};
