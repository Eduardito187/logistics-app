// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_status.dart';
import 'driver_route_stop.dart';
import 'route_geometry.dart';

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
    this.routeGeometry,
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

  /// Street-level route geometry from the published plan (planning), matched by vehicle+date. Null until the routing run computes it or if no plan matches.
  @JsonKey(name: 'route_geometry')
  final RouteGeometry? routeGeometry;

  Map<String, Object?> toJson() => _$DriverRouteToJson(this);
}
