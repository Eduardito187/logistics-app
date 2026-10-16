// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_vehicle_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterVehicleRequest _$RegisterVehicleRequestFromJson(
  Map<String, dynamic> json,
) => RegisterVehicleRequest(
  plate: json['plate'] as String,
  capacityKg: (json['capacity_kg'] as num).toInt(),
  capacityM3: json['capacity_m3'] as num,
  homeBaseNodeId: json['home_base_node_id'] as String,
  status: json['status'] == null
      ? null
      : VehicleStatus.fromJson(json['status'] as String),
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => DocumentExpiry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RegisterVehicleRequestToJson(
  RegisterVehicleRequest instance,
) => <String, dynamic>{
  'plate': instance.plate,
  'capacity_kg': instance.capacityKg,
  'capacity_m3': instance.capacityM3,
  'home_base_node_id': instance.homeBaseNodeId,
  'status': instance.status,
  'documents': instance.documents,
};
