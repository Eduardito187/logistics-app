// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_assemble_crew_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetAssembleCrewData _$FleetAssembleCrewDataFromJson(
  Map<String, dynamic> json,
) => FleetAssembleCrewData(
  status: json['status'] as String?,
  outcome: json['outcome'] == null
      ? null
      : FleetAssembleCrewDataOutcome.fromJson(json['outcome'] as String),
  driverId: json['driver_id'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  assembledFor: json['assembled_for'] == null
      ? null
      : DateTime.parse(json['assembled_for'] as String),
  crewId: json['crew_id'] as String?,
  vehiclePlate: json['vehicle_plate'] as String?,
  previousVehiclePlate: json['previous_vehicle_plate'] as String?,
  helpers: (json['helpers'] as List<dynamic>?)
      ?.map((e) => Helpers2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FleetAssembleCrewDataToJson(
  FleetAssembleCrewData instance,
) => <String, dynamic>{
  'status': instance.status,
  'outcome': instance.outcome,
  'driver_id': instance.driverId,
  'vehicle_id': instance.vehicleId,
  'assembled_for': instance.assembledFor?.toIso8601String(),
  'crew_id': instance.crewId,
  'vehicle_plate': instance.vehiclePlate,
  'previous_vehicle_plate': instance.previousVehiclePlate,
  'helpers': instance.helpers,
};
