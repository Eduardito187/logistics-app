// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_delivery_calendar_blocked_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveryCalendarBlockedRequestBody
_$AppDeliveryCalendarBlockedRequestBodyFromJson(Map<String, dynamic> json) =>
    AppDeliveryCalendarBlockedRequestBody(
      date: DateTime.parse(json['date'] as String),
      reason: json['reason'] as String,
      municipalityId: json['municipality_id'] as String?,
    );

Map<String, dynamic> _$AppDeliveryCalendarBlockedRequestBodyToJson(
  AppDeliveryCalendarBlockedRequestBody instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'municipality_id': instance.municipalityId,
  'reason': instance.reason,
};
