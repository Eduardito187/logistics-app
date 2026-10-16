// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip_status.dart';

part 'trip.g.dart';

/// Un recorrido (trip) de un vehículo con sus métricas crudas y legibles.
@JsonSerializable()
class Trip {
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.status,
    required this.startedAt,
    required this.distanceM,
    required this.durationS,
    required this.movingS,
    required this.idleS,
    required this.maxSpeedKph,
    required this.pingCount,
    required this.distanceKm,
    required this.durationMin,
    required this.movingMin,
    required this.idleMin,
    this.driverId,
    this.routeId,
    this.endedAt,
  });

  factory Trip.fromJson(Map<String, Object?> json) => _$TripFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'route_id')
  final String? routeId;
  final TripStatus status;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @JsonKey(name: 'distance_m')
  final double distanceM;
  @JsonKey(name: 'duration_s')
  final int durationS;
  @JsonKey(name: 'moving_s')
  final int movingS;
  @JsonKey(name: 'idle_s')
  final int idleS;
  @JsonKey(name: 'max_speed_kph')
  final double maxSpeedKph;
  @JsonKey(name: 'ping_count')
  final int pingCount;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'duration_min')
  final int durationMin;
  @JsonKey(name: 'moving_min')
  final int movingMin;
  @JsonKey(name: 'idle_min')
  final int idleMin;

  Map<String, Object?> toJson() => _$TripToJson(this);
}
