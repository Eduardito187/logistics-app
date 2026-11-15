// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'current_vehicle.g.dart';

@JsonSerializable()
class CurrentVehicle {
  const CurrentVehicle({
    this.crewId,
    this.vehicleId,
    this.plate,
    this.assembledFor,
  });

  factory CurrentVehicle.fromJson(Map<String, Object?> json) =>
      _$CurrentVehicleFromJson(json);

  @JsonKey(name: 'crew_id')
  final String? crewId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final String? plate;
  @JsonKey(name: 'assembled_for')
  final DateTime? assembledFor;

  Map<String, Object?> toJson() => _$CurrentVehicleToJson(this);
}
