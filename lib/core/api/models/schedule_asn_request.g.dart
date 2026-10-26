// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_asn_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleAsnRequest _$ScheduleAsnRequestFromJson(Map<String, dynamic> json) =>
    ScheduleAsnRequest(
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );

Map<String, dynamic> _$ScheduleAsnRequestToJson(ScheduleAsnRequest instance) =>
    <String, dynamic>{
      'appointment_date': instance.appointmentDate.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
