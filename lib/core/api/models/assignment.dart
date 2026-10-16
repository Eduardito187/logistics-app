// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'tariff.dart';
import 'vehicle_class.dart';

part 'assignment.g.dart';

@JsonSerializable()
class Assignment {
  const Assignment({
    required this.volumeM3,
    required this.vehicleClass,
    required this.tariff,
  });

  factory Assignment.fromJson(Map<String, Object?> json) =>
      _$AssignmentFromJson(json);

  @JsonKey(name: 'volume_m3')
  final double volumeM3;
  @JsonKey(name: 'vehicle_class')
  final VehicleClass vehicleClass;
  final Tariff? tariff;

  Map<String, Object?> toJson() => _$AssignmentToJson(this);
}
