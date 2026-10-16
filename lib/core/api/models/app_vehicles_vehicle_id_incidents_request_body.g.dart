// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_vehicles_vehicle_id_incidents_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVehiclesVehicleIdIncidentsRequestBody
_$AppVehiclesVehicleIdIncidentsRequestBodyFromJson(Map<String, dynamic> json) =>
    AppVehiclesVehicleIdIncidentsRequestBody(
      severity: Severity.fromJson(json['severity'] as String),
      type: Type.fromJson(json['type'] as String),
      routeId: json['route_id'] as String?,
      note: json['note'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      occurredAt: json['occurred_at'] == null
          ? null
          : DateTime.parse(json['occurred_at'] as String),
    );

Map<String, dynamic> _$AppVehiclesVehicleIdIncidentsRequestBodyToJson(
  AppVehiclesVehicleIdIncidentsRequestBody instance,
) => <String, dynamic>{
  'severity': instance.severity,
  'type': instance.type,
  'route_id': instance.routeId,
  'note': instance.note,
  'lat': instance.lat,
  'lng': instance.lng,
  'occurred_at': instance.occurredAt?.toIso8601String(),
};
