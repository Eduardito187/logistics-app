// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'windows.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Windows _$WindowsFromJson(Map<String, dynamic> json) => Windows(
  timeSlot: json['time_slot'] as String,
  unit: json['unit'] as String,
  quantity: json['quantity'] as num,
);

Map<String, dynamic> _$WindowsToJson(Windows instance) => <String, dynamic>{
  'time_slot': instance.timeSlot,
  'unit': instance.unit,
  'quantity': instance.quantity,
};
