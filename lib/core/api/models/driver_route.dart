// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_status.dart';
import 'driver_route_stop.dart';
import 'lat_lng_point.dart';
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
    this.offRoute,
    this.offRouteSince,
    this.rerouteGeometry,
    this.startedAt,
    this.closedAt,
    this.failedStops,
    this.rescheduledStops,
    this.currentStop,
    this.routeGeometry,
  });

  factory DriverRoute.fromJson(Map<String, Object?> json) =>
      _$DriverRouteFromJson(json);

  /// Verdad del backend (motor único de ETA) sobre si el camión está fuera de su ruta planificada por desvío sostenido. Reemplaza el cálculo local de la app para el cartel "Fuera de ruta".
  @JsonKey(name: 'off_route')
  final bool? offRoute;

  /// Desde cuándo se sostiene el desvío (ISO 8601), o null.
  @JsonKey(name: 'off_route_since')
  final DateTime? offRouteSince;

  /// Polilínea (posición actual → próxima parada pendiente) para redibujar la ruta cuando el vehículo está fuera de ruta. null salvo off_route=true.
  @JsonKey(name: 'reroute_geometry')
  final List<LatLngPoint>? rerouteGeometry;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'route_date')
  final DateTime routeDate;
  final DriverRouteStatus status;
  @JsonKey(name: 'total_stops')
  final int totalStops;

  /// Paradas ENTREGADAS con éxito (solo entregas). NO incluye fallidas ni replanificadas: esas van en failed_stops / rescheduled_stops.
  @JsonKey(name: 'completed_stops')
  final int completedStops;

  /// Paradas con intento de entrega fallido.
  @JsonKey(name: 'failed_stops')
  final int? failedStops;

  /// Paradas replanificadas por incidente del camión (sacadas de esta ruta).
  @JsonKey(name: 'rescheduled_stops')
  final int? rescheduledStops;
  @JsonKey(name: 'stops_remaining')
  final int stopsRemaining;
  @JsonKey(name: 'current_stop')
  final DriverRouteStop? currentStop;
  final List<DriverRouteStop> stops;

  /// Planned route geometry, matched by vehicle+date: the street-level geometry persisted with the plan (computed on the fly if the plan still lacks it); if there is no plan, a straight line through the route stops in sequence. Null only when fewer than two stops have coordinates.
  @JsonKey(name: 'route_geometry')
  final RouteGeometry? routeGeometry;

  Map<String, Object?> toJson() => _$DriverRouteToJson(this);
}
