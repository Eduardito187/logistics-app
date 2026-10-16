// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_vehicle_odometer_request.g.dart';

@JsonSerializable()
class UpdateVehicleOdometerRequest {
  const UpdateVehicleOdometerRequest({required this.km});

  factory UpdateVehicleOdometerRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateVehicleOdometerRequestFromJson(json);

  final int km;

  Map<String, Object?> toJson() => _$UpdateVehicleOdometerRequestToJson(this);
}
