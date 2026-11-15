// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_register_vehicle_data.g.dart';

@JsonSerializable()
class FleetRegisterVehicleData {
  const FleetRegisterVehicleData({this.status, this.plate});

  factory FleetRegisterVehicleData.fromJson(Map<String, Object?> json) =>
      _$FleetRegisterVehicleDataFromJson(json);

  final String? status;
  final String? plate;

  Map<String, Object?> toJson() => _$FleetRegisterVehicleDataToJson(this);
}
