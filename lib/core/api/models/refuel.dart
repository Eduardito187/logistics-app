// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_type.dart';

part 'refuel.g.dart';

/// A fuel refuel of an owned-fleet vehicle (total = price per liter x liters)
@JsonSerializable()
class Refuel {
  const Refuel({
    required this.id,
    required this.vehicleId,
    required this.fuelType,
    required this.liters,
    required this.pricePerLiterCents,
    required this.totalCostCents,
    required this.currency,
    required this.fullTank,
    required this.refueledAt,
    this.driverId,
    this.odometerKm,
    this.station,
    this.note,
  });

  factory Refuel.fromJson(Map<String, Object?> json) => _$RefuelFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'fuel_type')
  final FuelType fuelType;
  final double liters;
  @JsonKey(name: 'price_per_liter_cents')
  final int pricePerLiterCents;
  @JsonKey(name: 'total_cost_cents')
  final int totalCostCents;
  final String currency;
  @JsonKey(name: 'odometer_km')
  final int? odometerKm;
  final String? station;
  @JsonKey(name: 'full_tank')
  final bool fullTank;
  @JsonKey(name: 'refueled_at')
  final DateTime refueledAt;
  final String? note;

  Map<String, Object?> toJson() => _$RefuelToJson(this);
}
