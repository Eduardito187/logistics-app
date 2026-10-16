// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'define_capacity_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefineCapacityRequest _$DefineCapacityRequestFromJson(
  Map<String, dynamic> json,
) => DefineCapacityRequest(
  date: DateTime.parse(json['date'] as String),
  timeSlot: json['time_slot'] as String,
  unit: CapacityUnit.fromJson(json['unit'] as String),
  total: (json['total'] as num).toDouble(),
  nodeId: json['node_id'] as String?,
  zoneId: json['zone_id'] as String?,
);

Map<String, dynamic> _$DefineCapacityRequestToJson(
  DefineCapacityRequest instance,
) => <String, dynamic>{
  'node_id': instance.nodeId,
  'zone_id': instance.zoneId,
  'date': instance.date.toIso8601String(),
  'time_slot': instance.timeSlot,
  'unit': instance.unit,
  'total': instance.total,
};
