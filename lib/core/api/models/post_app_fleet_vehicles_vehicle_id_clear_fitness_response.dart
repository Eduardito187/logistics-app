// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_clear_vehicle_fitness_data.dart';

part 'post_app_fleet_vehicles_vehicle_id_clear_fitness_response.g.dart';

@JsonSerializable()
class PostAppFleetVehiclesVehicleIdClearFitnessResponse {
  const PostAppFleetVehiclesVehicleIdClearFitnessResponse({this.data});

  factory PostAppFleetVehiclesVehicleIdClearFitnessResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppFleetVehiclesVehicleIdClearFitnessResponseFromJson(json);

  final FleetClearVehicleFitnessData? data;

  Map<String, Object?> toJson() =>
      _$PostAppFleetVehiclesVehicleIdClearFitnessResponseToJson(this);
}
