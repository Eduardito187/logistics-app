// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_fitness.dart';

part 'get_app_fleet_vehicles_vehicle_id_fitness_response.g.dart';

@JsonSerializable()
class GetAppFleetVehiclesVehicleIdFitnessResponse {
  const GetAppFleetVehiclesVehicleIdFitnessResponse({required this.data});

  factory GetAppFleetVehiclesVehicleIdFitnessResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetVehiclesVehicleIdFitnessResponseFromJson(json);

  final VehicleFitness data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetVehiclesVehicleIdFitnessResponseToJson(this);
}
