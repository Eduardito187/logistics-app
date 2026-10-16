// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quoted_promise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuotedPromise _$QuotedPromiseFromJson(Map<String, dynamic> json) =>
    QuotedPromise(
      shipmentRef: json['shipment_ref'] as String,
      zoneId: json['zone_id'] as String,
      slotDate: DateTime.parse(json['slot_date'] as String),
      timeSlot: json['time_slot'] as String,
      status: QuotedPromiseStatus.fromJson(json['status'] as String),
    );

Map<String, dynamic> _$QuotedPromiseToJson(QuotedPromise instance) =>
    <String, dynamic>{
      'shipment_ref': instance.shipmentRef,
      'zone_id': instance.zoneId,
      'slot_date': instance.slotDate.toIso8601String(),
      'time_slot': instance.timeSlot,
      'status': instance.status,
    };
