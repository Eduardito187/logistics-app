// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'crew_driver.dart';
import 'crew_vehicle.dart';
import 'driver_route_status.dart';
import 'helpers2.dart';
import 'shift.dart';

part 'my_crew.g.dart';

/// The crew (driver + helpers) and vehicle assigned to the authenticated driver for a date. Read-only projection returned by fleetGetMyCrew.
@JsonSerializable()
class MyCrew {
  const MyCrew({
    required this.crewId,
    required this.date,
    required this.vehicle,
    required this.driver,
    required this.helpers,
    required this.shift,
    this.routeId,
    this.routeStatus,
  });

  factory MyCrew.fromJson(Map<String, Object?> json) => _$MyCrewFromJson(json);

  @JsonKey(name: 'crew_id')
  final String crewId;
  final DateTime date;
  final CrewVehicle vehicle;
  final CrewDriver driver;
  final List<Helpers2> helpers;

  /// Work-shift hours, or null when the crew was assembled without fixed hours.
  final Shift? shift;

  /// Ruta (salida) vigente del chofer: la abierta de su camión o, si no hay, la última del día. Null si el camión no tiene ruta ese día.
  @JsonKey(name: 'route_id')
  final String? routeId;

  /// Estado de esa ruta. Null cuando route_id es null.
  @JsonKey(name: 'route_status')
  final DriverRouteStatus? routeStatus;

  Map<String, Object?> toJson() => _$MyCrewToJson(this);
}
