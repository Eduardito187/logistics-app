// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receiving_dock_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivingDockDay _$ReceivingDockDayFromJson(Map<String, dynamic> json) =>
    ReceivingDockDay(
      date: DateTime.parse(json['date'] as String),
      appointments: (json['appointments'] as num).toInt(),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => ReceivingDockSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReceivingDockDayToJson(ReceivingDockDay instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'appointments': instance.appointments,
      'slots': instance.slots,
    };
