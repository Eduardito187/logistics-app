// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_telemetry_pings_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppTelemetryPingsRequestBody _$AppTelemetryPingsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppTelemetryPingsRequestBody(
  vehicleId: json['vehicle_id'] as String,
  pings: (json['pings'] as List<dynamic>)
      .map((e) => VehiclePing.fromJson(e as Map<String, dynamic>))
      .toList(),
  driverId: json['driver_id'] as String?,
  routeId: json['route_id'] as String?,
);

Map<String, dynamic> _$AppTelemetryPingsRequestBodyToJson(
  AppTelemetryPingsRequestBody instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'route_id': instance.routeId,
  'pings': instance.pings,
};
