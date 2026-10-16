// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integrations_telemetry_pings_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationsTelemetryPingsRequestBody
_$IntegrationsTelemetryPingsRequestBodyFromJson(Map<String, dynamic> json) =>
    IntegrationsTelemetryPingsRequestBody(
      vehicleId: json['vehicle_id'] as String,
      pings: (json['pings'] as List<dynamic>)
          .map((e) => VehiclePing.fromJson(e as Map<String, dynamic>))
          .toList(),
      driverId: json['driver_id'] as String?,
      routeId: json['route_id'] as String?,
    );

Map<String, dynamic> _$IntegrationsTelemetryPingsRequestBodyToJson(
  IntegrationsTelemetryPingsRequestBody instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'route_id': instance.routeId,
  'pings': instance.pings,
};
