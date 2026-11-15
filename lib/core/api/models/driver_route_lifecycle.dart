// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_status.dart';

part 'driver_route_lifecycle.g.dart';

@JsonSerializable()
class DriverRouteLifecycle {
  const DriverRouteLifecycle({
    required this.id,
    required this.vehicleId,
    required this.routeDate,
    required this.status,
    required this.startedAt,
    required this.closedAt,
    required this.totalStops,
    required this.completedStops,
    required this.stopsRemaining,
    required this.pendingStops,
    this.startOdometerKm,
    this.closeOdometerKm,
    this.failedStops,
    this.rescheduledStops,
  });

  factory DriverRouteLifecycle.fromJson(Map<String, Object?> json) =>
      _$DriverRouteLifecycleFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'route_date')
  final DateTime routeDate;
  final DriverRouteStatus status;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'start_odometer_km')
  final num? startOdometerKm;
  @JsonKey(name: 'close_odometer_km')
  final num? closeOdometerKm;
  @JsonKey(name: 'total_stops')
  final int totalStops;

  /// Paradas ENTREGADAS con éxito al cierre (no incluye fallidas ni replanificadas).
  @JsonKey(name: 'completed_stops')
  final int completedStops;
  @JsonKey(name: 'failed_stops')
  final int? failedStops;
  @JsonKey(name: 'rescheduled_stops')
  final int? rescheduledStops;
  @JsonKey(name: 'stops_remaining')
  final int stopsRemaining;
  @JsonKey(name: 'pending_stops')
  final int pendingStops;

  Map<String, Object?> toJson() => _$DriverRouteLifecycleToJson(this);
}
