// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Params _$ParamsFromJson(Map<String, dynamic> json) => Params(
  departAt: json['depart_at'] == null
      ? null
      : DateTime.parse(json['depart_at'] as String),
  capacitySlack: json['capacity_slack'] as num?,
  defaultWeightKgPerPackage: json['default_weight_kg_per_package'] as num?,
  defaultVolumeM3PerPackage: json['default_volume_m3_per_package'] as num?,
  originNodeId: json['origin_node_id'] as String?,
);

Map<String, dynamic> _$ParamsToJson(Params instance) => <String, dynamic>{
  'depart_at': instance.departAt?.toIso8601String(),
  'capacity_slack': instance.capacitySlack,
  'default_weight_kg_per_package': instance.defaultWeightKgPerPackage,
  'default_volume_m3_per_package': instance.defaultVolumeM3PerPackage,
  'origin_node_id': instance.originNodeId,
};
