// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_route_order.dart';

part 'maintenance_route_outcome.g.dart';

/// Qué pasó con las paradas pendientes de la ruta del camión enviado a mantenimiento
@JsonSerializable()
class MaintenanceRouteOutcome {
  const MaintenanceRouteOutcome({
    this.pendingStops,
    this.reassignedToVehicleId,
    this.reassigned,
    this.pendingReassignment,
  });

  factory MaintenanceRouteOutcome.fromJson(Map<String, Object?> json) =>
      _$MaintenanceRouteOutcomeFromJson(json);

  /// Paradas pendientes que tenía
  @JsonKey(name: 'pending_stops')
  final int? pendingStops;
  @JsonKey(name: 'reassigned_to_vehicle_id')
  final String? reassignedToVehicleId;

  /// Pedidos que pasaron al otro camión
  final List<MaintenanceRouteOrder>? reassigned;

  /// Pedidos liberados de la ruta que quedan por asignar
  @JsonKey(name: 'pending_reassignment')
  final List<MaintenanceRouteOrder>? pendingReassignment;

  Map<String, Object?> toJson() => _$MaintenanceRouteOutcomeToJson(this);
}
