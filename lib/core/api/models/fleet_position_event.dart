// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_position_event.g.dart';

/// Carga del evento `fleet.position` (tema fleet: canales `private-fleet.all` / `private-fleet.city.<ciudad>`). Es un objeto idéntico a un elemento de `data` de GET /app/telemetry/fleet/live: se aplica sobre la lista por `vehicle_id`. Como mucho uno por vehículo cada 5 s.
@JsonSerializable()
class FleetPositionEvent {
  const FleetPositionEvent({
    required this.vehicleId,
    required this.lat,
    required this.lng,
    required this.moving,
    required this.recordedAt,
    this.plate,
    this.driverId,
    this.baseNodeId,
    this.baseNodeName,
    this.city,
    this.driverName,
    this.updatedAt,
    this.speedKph,
    this.heading,
    this.ignition,
    this.routeId,
  });

  factory FleetPositionEvent.fromJson(Map<String, Object?> json) =>
      _$FleetPositionEventFromJson(json);

  final String? plate;
  @JsonKey(name: 'driver_id')
  final String? driverId;

  /// Sede del vehículo (nodo base).
  @JsonKey(name: 'base_node_id')
  final String? baseNodeId;
  @JsonKey(name: 'base_node_name')
  final String? baseNodeName;

  /// Departamento de la sede (la "ciudad" del camión), para agrupar la flota a nivel nacional.
  final String? city;
  @JsonKey(name: 'driver_name')
  final String? driverName;

  /// Server time the position changed (cursor for ?since).
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final double lat;
  final double lng;
  @JsonKey(name: 'speed_kph')
  final double? speedKph;
  final int? heading;
  final bool? ignition;
  final bool moving;
  @JsonKey(name: 'route_id')
  final String? routeId;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;

  Map<String, Object?> toJson() => _$FleetPositionEventToJson(this);
}
