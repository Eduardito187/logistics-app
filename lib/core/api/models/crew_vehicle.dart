// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'crew_vehicle.g.dart';

/// Assigned vehicle. `id` is always present; the other fields are null when the vehicle master record cannot be resolved.
@JsonSerializable()
class CrewVehicle {
  const CrewVehicle({
    required this.id,
    required this.plate,
    required this.capacityKg,
    required this.capacityM3,
    required this.status,
  });

  factory CrewVehicle.fromJson(Map<String, Object?> json) =>
      _$CrewVehicleFromJson(json);

  final String id;
  final String? plate;
  @JsonKey(name: 'capacity_kg')
  final int? capacityKg;
  @JsonKey(name: 'capacity_m3')
  final double? capacityM3;
  final String? status;

  Map<String, Object?> toJson() => _$CrewVehicleToJson(this);
}
