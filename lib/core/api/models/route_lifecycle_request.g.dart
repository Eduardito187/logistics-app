// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_lifecycle_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteLifecycleRequest _$RouteLifecycleRequestFromJson(
  Map<String, dynamic> json,
) => RouteLifecycleRequest(
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  routeDate: json['route_date'] == null
      ? null
      : DateTime.parse(json['route_date'] as String),
  odometerKm: json['odometer_km'] as num?,
  lat: json['lat'] as num?,
  lng: json['lng'] as num?,
);

Map<String, dynamic> _$RouteLifecycleRequestToJson(
  RouteLifecycleRequest instance,
) => <String, dynamic>{
  'occurred_at': instance.occurredAt.toIso8601String(),
  'route_date': instance.routeDate?.toIso8601String(),
  'odometer_km': instance.odometerKm,
  'lat': instance.lat,
  'lng': instance.lng,
};
