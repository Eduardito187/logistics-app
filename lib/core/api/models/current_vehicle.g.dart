// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentVehicle _$CurrentVehicleFromJson(Map<String, dynamic> json) =>
    CurrentVehicle(
      crewId: json['crew_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      plate: json['plate'] as String?,
      assembledFor: json['assembled_for'] == null
          ? null
          : DateTime.parse(json['assembled_for'] as String),
    );

Map<String, dynamic> _$CurrentVehicleToJson(CurrentVehicle instance) =>
    <String, dynamic>{
      'crew_id': instance.crewId,
      'vehicle_id': instance.vehicleId,
      'plate': instance.plate,
      'assembled_for': instance.assembledFor?.toIso8601String(),
    };
