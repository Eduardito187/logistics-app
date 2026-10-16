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
    );

Map<String, dynamic> _$AssembleCrewRequestToJson(
  AssembleCrewRequest instance,
) => <String, dynamic>{
  'driver_id': instance.driverId,
  'helper_ids': instance.helperIds,
  'vehicle_id': instance.vehicleId,
  'assembled_for': instance.assembledFor.toIso8601String(),
};
