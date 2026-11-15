// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_assemble_crew_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetAssembleCrewData _$FleetAssembleCrewDataFromJson(
  Map<String, dynamic> json,
) => FleetAssembleCrewData(
  status: json['status'] as String?,
  driverId: json['driver_id'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  assembledFor: json['assembled_for'] == null
      ? null
      : DateTime.parse(json['assembled_for'] as String),
);

Map<String, dynamic> _$FleetAssembleCrewDataToJson(
  FleetAssembleCrewData instance,
) => <String, dynamic>{
  'status': instance.status,
  'driver_id': instance.driverId,
  'vehicle_id': instance.vehicleId,
  'assembled_for': instance.assembledFor?.toIso8601String(),
};
