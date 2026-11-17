// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assemble_crew_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssembleCrewRequest _$AssembleCrewRequestFromJson(Map<String, dynamic> json) =>
    AssembleCrewRequest(
      driverId: json['driver_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      assembledFor: DateTime.parse(json['assembled_for'] as String),
      helperIds: (json['helper_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      shiftStartsAt: json['shift_starts_at'] == null
          ? null
          : DateTime.parse(json['shift_starts_at'] as String),
      shiftEndsAt: json['shift_ends_at'] == null
          ? null
          : DateTime.parse(json['shift_ends_at'] as String),
      replace: json['replace'] as bool?,
    );

Map<String, dynamic> _$AssembleCrewRequestToJson(
  AssembleCrewRequest instance,
) => <String, dynamic>{
  'driver_id': instance.driverId,
  'helper_ids': instance.helperIds,
  'vehicle_id': instance.vehicleId,
  'assembled_for': instance.assembledFor.toIso8601String(),
  'shift_starts_at': instance.shiftStartsAt?.toIso8601String(),
  'shift_ends_at': instance.shiftEndsAt?.toIso8601String(),
  'replace': instance.replace,
};
