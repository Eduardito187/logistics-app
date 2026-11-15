// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_clear_vehicle_fitness_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetClearVehicleFitnessData _$FleetClearVehicleFitnessDataFromJson(
  Map<String, dynamic> json,
) => FleetClearVehicleFitnessData(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  fitness: json['fitness'] == null
      ? null
      : VehicleFitness.fromJson(json['fitness'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FleetClearVehicleFitnessDataToJson(
  FleetClearVehicleFitnessData instance,
) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'fitness': instance.fitness,
};
