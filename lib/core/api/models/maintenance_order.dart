// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_item.dart';
import 'maintenance_order_type.dart';
import 'maintenance_status.dart';

part 'maintenance_order.g.dart';

/// A maintenance order of a vehicle
@JsonSerializable()
class MaintenanceOrder {
  const MaintenanceOrder({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.status,
    required this.items,
    required this.totalCostCents,
    required this.currency,
    this.odometerKm,
    this.workshop,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.note,
  });

  factory MaintenanceOrder.fromJson(Map<String, Object?> json) =>
      _$MaintenanceOrderFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final MaintenanceOrderType type;
  final MaintenanceStatus status;
  @JsonKey(name: 'odometer_km')
  final int? odometerKm;
  final String? workshop;
  final List<MaintenanceItem> items;
  @JsonKey(name: 'total_cost_cents')
  final int totalCostCents;
  final String currency;
  @JsonKey(name: 'scheduled_at')
  final DateTime? scheduledAt;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final String? note;

  Map<String, Object?> toJson() => _$MaintenanceOrderToJson(this);
}
