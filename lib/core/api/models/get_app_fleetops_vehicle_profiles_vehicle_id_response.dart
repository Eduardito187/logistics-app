// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_profile.dart';

part 'get_app_fleetops_vehicle_profiles_vehicle_id_response.g.dart';

@JsonSerializable()
class GetAppFleetopsVehicleProfilesVehicleIdResponse {
  const GetAppFleetopsVehicleProfilesVehicleIdResponse({required this.data});

  factory GetAppFleetopsVehicleProfilesVehicleIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsVehicleProfilesVehicleIdResponseFromJson(json);

  final VehicleProfile data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsVehicleProfilesVehicleIdResponseToJson(this);
}
