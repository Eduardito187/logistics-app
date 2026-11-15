// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_delivery_calendar_blocked_request_body2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveryCalendarBlockedRequestBody2
_$AppDeliveryCalendarBlockedRequestBody2FromJson(Map<String, dynamic> json) =>
    AppDeliveryCalendarBlockedRequestBody2(
      date: DateTime.parse(json['date'] as String),
      municipalityId: json['municipality_id'] as String?,
    );

Map<String, dynamic> _$AppDeliveryCalendarBlockedRequestBody2ToJson(
  AppDeliveryCalendarBlockedRequestBody2 instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'municipality_id': instance.municipalityId,
};
