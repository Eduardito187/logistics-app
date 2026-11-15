// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  fitToDispatch: json['fit_to_dispatch'] as bool?,
  unfitSince: json['unfit_since'] == null
      ? null
      : DateTime.parse(json['unfit_since'] as String),
  unfitReason: json['unfit_reason'] as String?,
  unfitItems: (json['unfit_items'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  id: json['id'] as String?,
  plate: json['plate'] as String?,
  capacityKg: (json['capacity_kg'] as num?)?.toInt(),
  capacityM3: (json['capacity_m3'] as num?)?.toDouble(),
  homeBaseNodeId: json['home_base_node_id'] as String?,
  status: json['status'] == null
      ? null
      : VehicleStatus.fromJson(json['status'] as String),
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => DocumentExpiry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'fit_to_dispatch': instance.fitToDispatch,
  'unfit_since': instance.unfitSince?.toIso8601String(),
  'unfit_reason': instance.unfitReason,
  'unfit_items': instance.unfitItems,
  'id': instance.id,
  'plate': instance.plate,
  'capacity_kg': instance.capacityKg,
  'capacity_m3': instance.capacityM3,
  'home_base_node_id': instance.homeBaseNodeId,
  'status': instance.status,
  'documents': instance.documents,
};
