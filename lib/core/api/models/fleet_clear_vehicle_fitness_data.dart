// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_fitness.dart';

part 'fleet_clear_vehicle_fitness_data.g.dart';

@JsonSerializable()
class FleetClearVehicleFitnessData {
  const FleetClearVehicleFitnessData({
    this.status,
    this.vehicleId,
    this.fitness,
  });

  factory FleetClearVehicleFitnessData.fromJson(Map<String, Object?> json) =>
      _$FleetClearVehicleFitnessDataFromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final VehicleFitness? fitness;

  Map<String, Object?> toJson() => _$FleetClearVehicleFitnessDataToJson(this);
}
