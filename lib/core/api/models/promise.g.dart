// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Promise _$PromiseFromJson(Map<String, dynamic> json) => Promise(
  id: json['id'] as String,
  shipmentRef: json['shipment_ref'] as String,
  zoneId: json['zone_id'] as String,
  zoneName: json['zone_name'] as String?,
  slotDate: DateTime.parse(json['slot_date'] as String),
  timeSlot: json['time_slot'] as String,
  status: PromiseStatus.fromJson(json['status'] as String),
  reservedUntil: json['reserved_until'] == null
      ? null
      : DateTime.parse(json['reserved_until'] as String),
);

Map<String, dynamic> _$PromiseToJson(Promise instance) => <String, dynamic>{
  'id': instance.id,
  'shipment_ref': instance.shipmentRef,
  'zone_id': instance.zoneId,
  'zone_name': instance.zoneName,
  'slot_date': instance.slotDate.toIso8601String(),
  'time_slot': instance.timeSlot,
  'status': instance.status,
  'reserved_until': instance.reservedUntil?.toIso8601String(),
};
