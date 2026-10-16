// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_telemetry_geofences_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppTelemetryGeofencesRequestBody _$AppTelemetryGeofencesRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppTelemetryGeofencesRequestBody(
  name: json['name'] as String,
  type: GeofenceType.fromJson(json['type'] as String),
  polygon: (json['polygon'] as List<dynamic>)
      .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  nodeRef: json['node_ref'] as String?,
);

Map<String, dynamic> _$AppTelemetryGeofencesRequestBodyToJson(
  AppTelemetryGeofencesRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'polygon': instance.polygon,
  'node_ref': instance.nodeRef,
};
