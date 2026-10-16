// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan_status.dart';
import 'planned_stop.dart';
import 'route_geometry.dart';

part 'plan.g.dart';

@JsonSerializable()
class Plan {
  const Plan({
    required this.id,
    required this.planDate,
    required this.vehicleId,
    required this.status,
    required this.stops,
    this.routeGeometry,
  });

  factory Plan.fromJson(Map<String, Object?> json) => _$PlanFromJson(json);

  final String id;
  @JsonKey(name: 'plan_date')
  final DateTime planDate;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final PlanStatus status;
  final List<PlannedStop> stops;

  /// Street-level route geometry computed server-side and persisted with the plan, so the map draws it without depending on the browser. Null until the routing run computes it.
  @JsonKey(name: 'route_geometry')
  final RouteGeometry? routeGeometry;

  Map<String, Object?> toJson() => _$PlanToJson(this);
}
