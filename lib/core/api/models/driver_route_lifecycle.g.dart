// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_route_lifecycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverRouteLifecycle _$DriverRouteLifecycleFromJson(
  Map<String, dynamic> json,
) => DriverRouteLifecycle(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  routeDate: DateTime.parse(json['route_date'] as String),
  status: DriverRouteStatus.fromJson(json['status'] as String),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  totalStops: (json['total_stops'] as num).toInt(),
  completedStops: (json['completed_stops'] as num).toInt(),
  stopsRemaining: (json['stops_remaining'] as num).toInt(),
  pendingStops: (json['pending_stops'] as num).toInt(),
  startOdometerKm: json['start_odometer_km'] as num?,
  closeOdometerKm: json['close_odometer_km'] as num?,
  failedStops: (json['failed_stops'] as num?)?.toInt(),
  rescheduledStops: (json['rescheduled_stops'] as num?)?.toInt(),
);

Map<String, dynamic> _$DriverRouteLifecycleToJson(
  DriverRouteLifecycle instance,
) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'route_date': instance.routeDate.toIso8601String(),
  'status': instance.status,
  'started_at': instance.startedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'start_odometer_km': instance.startOdometerKm,
  'close_odometer_km': instance.closeOdometerKm,
  'total_stops': instance.totalStops,
  'completed_stops': instance.completedStops,
  'failed_stops': instance.failedStops,
  'rescheduled_stops': instance.rescheduledStops,
  'stops_remaining': instance.stopsRemaining,
  'pending_stops': instance.pendingStops,
};
