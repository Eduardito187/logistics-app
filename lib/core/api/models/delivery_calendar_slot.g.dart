// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_calendar_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCalendarSlot _$DeliveryCalendarSlotFromJson(
  Map<String, dynamic> json,
) => DeliveryCalendarSlot(
  timeSlot: json['time_slot'] as String,
  capacity: json['capacity'] as num?,
  used: json['used'] as num,
  unit: DeliveryCalendarSlotUnit.fromJson(json['unit'] as String),
  blocked: json['blocked'] as bool,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$DeliveryCalendarSlotToJson(
  DeliveryCalendarSlot instance,
) => <String, dynamic>{
  'time_slot': instance.timeSlot,
  'capacity': instance.capacity,
  'used': instance.used,
  'unit': instance.unit,
  'blocked': instance.blocked,
  'reason': instance.reason,
};
