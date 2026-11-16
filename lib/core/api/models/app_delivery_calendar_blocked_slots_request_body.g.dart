// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_delivery_calendar_blocked_slots_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveryCalendarBlockedSlotsRequestBody
_$AppDeliveryCalendarBlockedSlotsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppDeliveryCalendarBlockedSlotsRequestBody(
  date: DateTime.parse(json['date'] as String),
  timeSlot: json['time_slot'] as String,
  reason: json['reason'] as String,
  municipalityId: json['municipality_id'] as String?,
);

Map<String, dynamic> _$AppDeliveryCalendarBlockedSlotsRequestBodyToJson(
  AppDeliveryCalendarBlockedSlotsRequestBody instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'time_slot': instance.timeSlot,
  'reason': instance.reason,
  'municipality_id': instance.municipalityId,
};
