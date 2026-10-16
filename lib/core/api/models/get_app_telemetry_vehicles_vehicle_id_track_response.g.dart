// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_vehicles_vehicle_id_track_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryVehiclesVehicleIdTrackResponse
_$GetAppTelemetryVehiclesVehicleIdTrackResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryVehiclesVehicleIdTrackResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => VehiclePing.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppTelemetryVehiclesVehicleIdTrackResponseToJson(
  GetAppTelemetryVehiclesVehicleIdTrackResponse instance,
) => <String, dynamic>{'data': instance.data};
