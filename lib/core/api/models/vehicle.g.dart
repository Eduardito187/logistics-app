// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: json['id'] as String,
  plate: json['plate'] as String?,
  capacityKg: (json['capacity_kg'] as num?)?.toInt(),
  capacityM3: (json['capacity_m3'] as num?)?.toDouble(),
  status: json['status'] as String?,
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'plate': instance.plate,
  'capacity_kg': instance.capacityKg,
  'capacity_m3': instance.capacityM3,
  'status': instance.status,
};
