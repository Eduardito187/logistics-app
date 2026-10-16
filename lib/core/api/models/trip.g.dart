// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  status: TripStatus.fromJson(json['status'] as String),
  startedAt: DateTime.parse(json['started_at'] as String),
  distanceM: (json['distance_m'] as num).toDouble(),
  durationS: (json['duration_s'] as num).toInt(),
  movingS: (json['moving_s'] as num).toInt(),
  idleS: (json['idle_s'] as num).toInt(),
  maxSpeedKph: (json['max_speed_kph'] as num).toDouble(),
  pingCount: (json['ping_count'] as num).toInt(),
  distanceKm: (json['distance_km'] as num).toDouble(),
  durationMin: (json['duration_min'] as num).toInt(),
  movingMin: (json['moving_min'] as num).toInt(),
  idleMin: (json['idle_min'] as num).toInt(),
  driverId: json['driver_id'] as String?,
  routeId: json['route_id'] as String?,
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'route_id': instance.routeId,
  'status': instance.status,
  'started_at': instance.startedAt.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'moving_s': instance.movingS,
  'idle_s': instance.idleS,
  'max_speed_kph': instance.maxSpeedKph,
  'ping_count': instance.pingCount,
  'distance_km': instance.distanceKm,
  'duration_min': instance.durationMin,
  'moving_min': instance.movingMin,
  'idle_min': instance.idleMin,
};
