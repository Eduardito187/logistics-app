// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asn_appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsnAppointment _$AsnAppointmentFromJson(Map<String, dynamic> json) =>
    AsnAppointment(
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      timeSlot: json['time_slot'] as String,
    );

Map<String, dynamic> _$AsnAppointmentToJson(AsnAppointment instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'time_slot': instance.timeSlot,
    };
