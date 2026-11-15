// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_trip_checklist_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreTripChecklistResult _$PreTripChecklistResultFromJson(
  Map<String, dynamic> json,
) => PreTripChecklistResult(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  driverId: json['driver_id'] as String?,
  performedOn: json['performed_on'] == null
      ? null
      : DateTime.parse(json['performed_on'] as String),
  inspectionId: json['inspection_id'] as String?,
  passed: json['passed'] as bool?,
  fitToDispatch: json['fit_to_dispatch'] as bool?,
  failedCritical: (json['failed_critical'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  missingCritical: (json['missing_critical'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  vehicleFitness: json['vehicle_fitness'] == null
      ? null
      : VehicleFitness.fromJson(
          json['vehicle_fitness'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PreTripChecklistResultToJson(
  PreTripChecklistResult instance,
) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'performed_on': instance.performedOn?.toIso8601String(),
  'inspection_id': instance.inspectionId,
  'passed': instance.passed,
  'fit_to_dispatch': instance.fitToDispatch,
  'failed_critical': instance.failedCritical,
  'missing_critical': instance.missingCritical,
  'vehicle_fitness': instance.vehicleFitness,
};
