// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_fleet_live_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryFleetLiveResponse _$GetAppTelemetryFleetLiveResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryFleetLiveResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => VehicleLive.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppTelemetryFleetLiveResponseToJson(
  GetAppTelemetryFleetLiveResponse instance,
) => <String, dynamic>{'data': instance.data};
