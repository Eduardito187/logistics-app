// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_fitness.g.dart';

@JsonSerializable()
class VehicleFitness {
  const VehicleFitness({
    required this.vehicleId,
    required this.plate,
    required this.date,
    required this.fitToDispatch,
    required this.unfitSince,
    required this.unfitReason,
    required this.unfitItems,
  });

  factory VehicleFitness.fromJson(Map<String, Object?> json) =>
      _$VehicleFitnessFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final String plate;
  final DateTime date;
  @JsonKey(name: 'fit_to_dispatch')
  final bool fitToDispatch;
  @JsonKey(name: 'unfit_since')
  final DateTime? unfitSince;
  @JsonKey(name: 'unfit_reason')
  final String? unfitReason;
  @JsonKey(name: 'unfit_items')
  final List<String> unfitItems;

  Map<String, Object?> toJson() => _$VehicleFitnessToJson(this);
}
