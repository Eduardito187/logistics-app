// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receiving_dock_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivingDockSlot _$ReceivingDockSlotFromJson(Map<String, dynamic> json) =>
    ReceivingDockSlot(
      timeSlot: json['time_slot'] as String,
      appointments: (json['appointments'] as num).toInt(),
    );

Map<String, dynamic> _$ReceivingDockSlotToJson(ReceivingDockSlot instance) =>
    <String, dynamic>{
      'time_slot': instance.timeSlot,
      'appointments': instance.appointments,
    };
