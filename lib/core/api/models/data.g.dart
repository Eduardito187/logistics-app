// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) => Data(
  id: json['id'] as String,
  name: json['name'] as String,
  vehicleType: json['vehicle_type'] as String?,
  active: json['active'] as bool,
  items: (json['items'] as List<dynamic>)
      .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  criticalKeys: (json['critical_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  vehicleFitness: json['vehicle_fitness'] == null
      ? null
      : VehicleFitness.fromJson(
          json['vehicle_fitness'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'vehicle_type': instance.vehicleType,
  'active': instance.active,
  'items': instance.items,
  'critical_keys': instance.criticalKeys,
  'vehicle_fitness': instance.vehicleFitness,
};
