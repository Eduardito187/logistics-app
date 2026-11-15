// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'clear_vehicle_fitness_request.g.dart';

@JsonSerializable()
class ClearVehicleFitnessRequest {
  const ClearVehicleFitnessRequest({required this.note});

  factory ClearVehicleFitnessRequest.fromJson(Map<String, Object?> json) =>
      _$ClearVehicleFitnessRequestFromJson(json);

  /// What was repaired (audited)
  final String note;

  Map<String, Object?> toJson() => _$ClearVehicleFitnessRequestToJson(this);
}
