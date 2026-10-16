// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

@JsonSerializable()
class Vehicle {
  const Vehicle({
    required this.id,
    required this.plate,
    required this.capacityKg,
    required this.capacityM3,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, Object?> json) =>
      _$VehicleFromJson(json);

  final String id;
  final String? plate;
  @JsonKey(name: 'capacity_kg')
  final int? capacityKg;
  @JsonKey(name: 'capacity_m3')
  final double? capacityM3;
  final String? status;

  Map<String, Object?> toJson() => _$VehicleToJson(this);
}
