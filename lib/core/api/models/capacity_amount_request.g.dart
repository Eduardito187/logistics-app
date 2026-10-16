// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capacity_amount_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CapacityAmountRequest _$CapacityAmountRequestFromJson(
  Map<String, dynamic> json,
) => CapacityAmountRequest(
  date: DateTime.parse(json['date'] as String),
  timeSlot: json['time_slot'] as String,
  unit: CapacityUnit.fromJson(json['unit'] as String),
  amount: (json['amount'] as num).toDouble(),
  nodeId: json['node_id'] as String?,
  zoneId: json['zone_id'] as String?,
);

Map<String, dynamic> _$CapacityAmountRequestToJson(
  CapacityAmountRequest instance,
) => <String, dynamic>{
  'node_id': instance.nodeId,
  'zone_id': instance.zoneId,
  'date': instance.date.toIso8601String(),
  'time_slot': instance.timeSlot,
  'unit': instance.unit,
  'amount': instance.amount,
};
