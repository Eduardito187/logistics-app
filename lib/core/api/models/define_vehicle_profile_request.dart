// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_type.dart';

part 'define_vehicle_profile_request.g.dart';

@JsonSerializable()
class DefineVehicleProfileRequest {
  const DefineVehicleProfileRequest({
    required this.vehicleId,
    this.brand,
    this.model,
    this.year,
    this.fuelType,
    this.tankLiters,
    this.vin,
    this.color,
  });

  factory DefineVehicleProfileRequest.fromJson(Map<String, Object?> json) =>
      _$DefineVehicleProfileRequestFromJson(json);

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

  Map<String, Object?> toJson() => _$DefineVehicleProfileRequestToJson(this);
}
