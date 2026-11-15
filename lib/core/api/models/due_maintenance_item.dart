// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'due_maintenance_item_service_kind.dart';
import 'due_maintenance_item_urgency.dart';

part 'due_maintenance_item.g.dart';

@JsonSerializable()
class DueMaintenanceItem {
  const DueMaintenanceItem({
    required this.vehicleId,
    required this.vehiclePlate,
    required this.planId,
    required this.serviceKind,
    required this.nextDueKm,
    required this.nextDueAt,
    required this.currentOdometerKm,
    required this.remainingKm,
    required this.daysRemaining,
    required this.overdue,
    required this.urgency,
  });

  factory DueMaintenanceItem.fromJson(Map<String, Object?> json) =>
      _$DueMaintenanceItemFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;
  @JsonKey(name: 'plan_id')
  final String? planId;
  @JsonKey(name: 'service_kind')
  final DueMaintenanceItemServiceKind serviceKind;
  @JsonKey(name: 'next_due_km')
  final int? nextDueKm;
  @JsonKey(name: 'next_due_at')
  final DateTime? nextDueAt;
  @JsonKey(name: 'current_odometer_km')
  final int? currentOdometerKm;

  /// next_due_km - current_odometer_km (negative when overdue)
  @JsonKey(name: 'remaining_km')
  final int? remainingKm;

  /// Calendar days to next_due_at (negative when overdue)
  @JsonKey(name: 'days_remaining')
  final int? daysRemaining;
  final bool overdue;
  final DueMaintenanceItemUrgency urgency;

  Map<String, Object?> toJson() => _$DueMaintenanceItemToJson(this);
}
