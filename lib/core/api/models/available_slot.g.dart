// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableSlot _$AvailableSlotFromJson(Map<String, dynamic> json) =>
    AvailableSlot(
      slotDate: DateTime.parse(json['slot_date'] as String),
      timeSlot: json['time_slot'] as String,
    );

Map<String, dynamic> _$AvailableSlotToJson(AvailableSlot instance) =>
    <String, dynamic>{
      'slot_date': instance.slotDate.toIso8601String(),
      'time_slot': instance.timeSlot,
    };
