// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_streets_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryStreetsResponse _$GetAppTelemetryStreetsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryStreetsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => StreetTraffic.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppTelemetryStreetsResponseToJson(
  GetAppTelemetryStreetsResponse instance,
) => <String, dynamic>{'data': instance.data};
