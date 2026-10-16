// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_telemetry_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleTelemetrySummary _$VehicleTelemetrySummaryFromJson(
  Map<String, dynamic> json,
) => VehicleTelemetrySummary(
  vehicleId: json['vehicle_id'] as String,
  date: DateTime.parse(json['date'] as String),
  distanceM: (json['distance_m'] as num).toDouble(),
  movingS: (json['moving_s'] as num).toInt(),
  idleS: (json['idle_s'] as num).toInt(),
  trips: (json['trips'] as num).toInt(),
  maxSpeedKph: (json['max_speed_kph'] as num).toDouble(),
  firstRecordedAt: json['first_recorded_at'] == null
      ? null
      : DateTime.parse(json['first_recorded_at'] as String),
  lastRecordedAt: json['last_recorded_at'] == null
      ? null
      : DateTime.parse(json['last_recorded_at'] as String),
);

Map<String, dynamic> _$VehicleTelemetrySummaryToJson(
  VehicleTelemetrySummary instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'date': instance.date.toIso8601String(),
  'distance_m': instance.distanceM,
  'moving_s': instance.movingS,
  'idle_s': instance.idleS,
  'trips': instance.trips,
  'max_speed_kph': instance.maxSpeedKph,
  'first_recorded_at': instance.firstRecordedAt?.toIso8601String(),
  'last_recorded_at': instance.lastRecordedAt?.toIso8601String(),
};
