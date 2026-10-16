// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_status.dart';
import 'driver_route_stop.dart';

part 'driver_route.g.dart';

/// The driver route sheet of a vehicle for a day, with its ordered stops
@JsonSerializable()
class DriverRoute {
  const DriverRoute({
    required this.id,
    required this.vehicleId,
    required this.routeDate,
    required this.status,
    required this.totalStops,
    required this.completedStops,
    required this.stopsRemaining,
    required this.stops,
    this.currentStop,
  });

  factory DriverRoute.fromJson(Map<String, Object?> json) =>
      _$DriverRouteFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'route_date')
  final DateTime routeDate;
  final DriverRouteStatus status;
  @JsonKey(name: 'total_stops')
  final int totalStops;
  @JsonKey(name: 'completed_stops')
  final int completedStops;
  @JsonKey(name: 'stops_remaining')
  final int stopsRemaining;
  @JsonKey(name: 'current_stop')
  final DriverRouteStop? currentStop;
  final List<DriverRouteStop> stops;

  Map<String, Object?> toJson() => _$DriverRouteToJson(this);
}
