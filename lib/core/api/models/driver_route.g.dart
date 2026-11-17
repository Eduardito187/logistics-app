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
  offRoute: json['off_route'] as bool?,
  offRouteSince: json['off_route_since'] == null
      ? null
      : DateTime.parse(json['off_route_since'] as String),
  rerouteGeometry: (json['reroute_geometry'] as List<dynamic>?)
      ?.map((e) => LatLngPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  failedStops: (json['failed_stops'] as num?)?.toInt(),
  rescheduledStops: (json['rescheduled_stops'] as num?)?.toInt(),
  currentStop: json['current_stop'] == null
      ? null
      : DriverRouteStop.fromJson(json['current_stop'] as Map<String, dynamic>),
  routeGeometry: json['route_geometry'] == null
      ? null
      : RouteGeometry.fromJson(json['route_geometry'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DriverRouteToJson(DriverRoute instance) =>
    <String, dynamic>{
      'off_route': instance.offRoute,
      'off_route_since': instance.offRouteSince?.toIso8601String(),
      'reroute_geometry': instance.rerouteGeometry,
      'started_at': instance.startedAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'route_date': instance.routeDate.toIso8601String(),
      'status': instance.status,
      'total_stops': instance.totalStops,
      'completed_stops': instance.completedStops,
      'failed_stops': instance.failedStops,
      'rescheduled_stops': instance.rescheduledStops,
      'stops_remaining': instance.stopsRemaining,
      'current_stop': instance.currentStop,
      'stops': instance.stops,
      'route_geometry': instance.routeGeometry,
    };
