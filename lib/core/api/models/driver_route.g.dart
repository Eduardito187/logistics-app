// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverRoute _$DriverRouteFromJson(Map<String, dynamic> json) => DriverRoute(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  routeDate: DateTime.parse(json['route_date'] as String),
  status: DriverRouteStatus.fromJson(json['status'] as String),
  totalStops: (json['total_stops'] as num).toInt(),
  completedStops: (json['completed_stops'] as num).toInt(),
  stopsRemaining: (json['stops_remaining'] as num).toInt(),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => DriverRouteStop.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentStop: json['current_stop'] == null
      ? null
      : DriverRouteStop.fromJson(json['current_stop'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DriverRouteToJson(DriverRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'route_date': instance.routeDate.toIso8601String(),
      'status': instance.status,
      'total_stops': instance.totalStops,
      'completed_stops': instance.completedStops,
      'stops_remaining': instance.stopsRemaining,
      'current_stop': instance.currentStop,
      'stops': instance.stops,
    };
