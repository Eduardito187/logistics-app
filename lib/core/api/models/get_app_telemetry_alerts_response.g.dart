// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_alerts_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryAlertsResponse _$GetAppTelemetryAlertsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryAlertsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Alert.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppTelemetryAlertsResponseToJson(
  GetAppTelemetryAlertsResponse instance,
) => <String, dynamic>{'data': instance.data};
