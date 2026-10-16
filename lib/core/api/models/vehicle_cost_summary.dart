// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_cost_summary.g.dart';

/// Cost summary of a vehicle in a period (TCO + cost per km)
@JsonSerializable()
class VehicleCostSummary {
  const VehicleCostSummary({
    required this.vehicleId,
    required this.from,
    required this.to,
    required this.fuelCents,
    required this.maintenanceCents,
    required this.expensesCents,
    required this.totalCents,
    required this.currency,
    required this.kilometers,
    this.costPerKmCents,
  });

  factory VehicleCostSummary.fromJson(Map<String, Object?> json) =>
      _$VehicleCostSummaryFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final DateTime from;
  final DateTime to;
  @JsonKey(name: 'fuel_cents')
  final int fuelCents;
  @JsonKey(name: 'maintenance_cents')
  final int maintenanceCents;
  @JsonKey(name: 'expenses_cents')
  final int expensesCents;
  @JsonKey(name: 'total_cents')
  final int totalCents;
  final String currency;
  final int kilometers;
  @JsonKey(name: 'cost_per_km_cents')
  final int? costPerKmCents;

  Map<String, Object?> toJson() => _$VehicleCostSummaryToJson(this);
}
