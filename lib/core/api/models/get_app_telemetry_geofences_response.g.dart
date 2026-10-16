// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_geofences_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryGeofencesResponse _$GetAppTelemetryGeofencesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryGeofencesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Geofence.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppTelemetryGeofencesResponseToJson(
  GetAppTelemetryGeofencesResponse instance,
) => <String, dynamic>{'data': instance.data};
