// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipality_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MunicipalitySlot _$MunicipalitySlotFromJson(Map<String, dynamic> json) =>
    MunicipalitySlot(
      municipalityId: json['municipality_id'] as String,
      slotDate: DateTime.parse(json['slot_date'] as String),
      timeSlot: json['time_slot'] as String,
      available: json['available'] as num,
    );

Map<String, dynamic> _$MunicipalitySlotToJson(MunicipalitySlot instance) =>
    <String, dynamic>{
      'municipality_id': instance.municipalityId,
      'slot_date': instance.slotDate.toIso8601String(),
      'time_slot': instance.timeSlot,
      'available': instance.available,
    };
