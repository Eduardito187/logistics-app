// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_telemetry_trips_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppTelemetryTripsResponse _$GetAppTelemetryTripsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppTelemetryTripsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Trip.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppTelemetryTripsResponseToJson(
  GetAppTelemetryTripsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
