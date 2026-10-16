// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_plan_service_kind.dart';

part 'maintenance_plan.g.dart';

/// A preventive maintenance plan of a vehicle (by km and/or days)
@JsonSerializable()
class MaintenancePlan {
  const MaintenancePlan({
    required this.id,
    required this.vehicleId,
    required this.serviceKind,
    required this.active,
    this.intervalKm,
    this.intervalDays,
    this.lastDoneKm,
    this.lastDoneAt,
    this.nextDueKm,
    this.nextDueAt,
  });

  factory MaintenancePlan.fromJson(Map<String, Object?> json) =>
      _$MaintenancePlanFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'service_kind')
  final MaintenancePlanServiceKind serviceKind;
  @JsonKey(name: 'interval_km')
  final int? intervalKm;
  @JsonKey(name: 'interval_days')
  final int? intervalDays;
  @JsonKey(name: 'last_done_km')
  final int? lastDoneKm;
  @JsonKey(name: 'last_done_at')
  final DateTime? lastDoneAt;
  @JsonKey(name: 'next_due_km')
  final int? nextDueKm;
  @JsonKey(name: 'next_due_at')
  final DateTime? nextDueAt;
  final bool active;

  Map<String, Object?> toJson() => _$MaintenancePlanToJson(this);
}
