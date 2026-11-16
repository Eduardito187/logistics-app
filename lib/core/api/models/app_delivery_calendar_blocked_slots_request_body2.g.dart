// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_delivery_calendar_blocked_slots_request_body2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveryCalendarBlockedSlotsRequestBody2
_$AppDeliveryCalendarBlockedSlotsRequestBody2FromJson(
  Map<String, dynamic> json,
) => AppDeliveryCalendarBlockedSlotsRequestBody2(
  date: DateTime.parse(json['date'] as String),
  timeSlot: json['time_slot'] as String,
  municipalityId: json['municipality_id'] as String?,
);

Map<String, dynamic> _$AppDeliveryCalendarBlockedSlotsRequestBody2ToJson(
  AppDeliveryCalendarBlockedSlotsRequestBody2 instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'time_slot': instance.timeSlot,
  'municipality_id': instance.municipalityId,
};
