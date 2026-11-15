// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crew_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrewVehicle _$CrewVehicleFromJson(Map<String, dynamic> json) => CrewVehicle(
  id: json['id'] as String,
  plate: json['plate'] as String?,
  capacityKg: (json['capacity_kg'] as num?)?.toInt(),
  capacityM3: (json['capacity_m3'] as num?)?.toDouble(),
  status: json['status'] as String?,
);

Map<String, dynamic> _$CrewVehicleToJson(CrewVehicle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plate': instance.plate,
      'capacity_kg': instance.capacityKg,
      'capacity_m3': instance.capacityM3,
      'status': instance.status,
    };
