// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_fitness.dart';

part 'pre_trip_checklist_result.g.dart';

@JsonSerializable()
class PreTripChecklistResult {
  const PreTripChecklistResult({
    this.status,
    this.vehicleId,
    this.driverId,
    this.performedOn,
    this.inspectionId,
    this.passed,
    this.fitToDispatch,
    this.failedCritical,
    this.missingCritical,
    this.vehicleFitness,
  });

  factory PreTripChecklistResult.fromJson(Map<String, Object?> json) =>
      _$PreTripChecklistResultFromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'performed_on')
  final DateTime? performedOn;
  @JsonKey(name: 'inspection_id')
  final String? inspectionId;
  final bool? passed;

  /// No failed critical item AND the vehicle is fit on that date
  @JsonKey(name: 'fit_to_dispatch')
  final bool? fitToDispatch;
  @JsonKey(name: 'failed_critical')
  final List<String>? failedCritical;
  @JsonKey(name: 'missing_critical')
  final List<String>? missingCritical;
  @JsonKey(name: 'vehicle_fitness')
  final VehicleFitness? vehicleFitness;

  Map<String, Object?> toJson() => _$PreTripChecklistResultToJson(this);
}
