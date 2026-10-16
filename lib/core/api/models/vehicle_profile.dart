// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_type.dart';

part 'vehicle_profile.g.dart';

/// The technical profile of a vehicle (1:1 by vehicle)
@JsonSerializable()
class VehicleProfile {
  const VehicleProfile({
    required this.id,
    required this.vehicleId,
    this.brand,
    this.model,
    this.year,
    this.fuelType,
    this.tankLiters,
    this.vin,
    this.color,
    this.currentOdometerKm,
  });

  factory VehicleProfile.fromJson(Map<String, Object?> json) =>
      _$VehicleProfileFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final String? brand;
  final String? model;
  final int? year;
  @JsonKey(name: 'fuel_type')
  final FuelType? fuelType;
  @JsonKey(name: 'tank_liters')
  final double? tankLiters;
  final String? vin;
  final String? color;
  @JsonKey(name: 'current_odometer_km')
  final int? currentOdometerKm;

  Map<String, Object?> toJson() => _$VehicleProfileToJson(this);
}
