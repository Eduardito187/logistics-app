// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reschedule_shipments_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RescheduleShipmentsRequest _$RescheduleShipmentsRequestFromJson(
  Map<String, dynamic> json,
) => RescheduleShipmentsRequest(
  scope: Scope.fromJson(json['scope'] as Map<String, dynamic>),
  newDate: DateTime.parse(json['new_date'] as String),
  windowStart: json['window_start'] as String,
  windowEnd: json['window_end'] as String,
  notifyCustomer: json['notify_customer'] as bool? ?? false,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$RescheduleShipmentsRequestToJson(
  RescheduleShipmentsRequest instance,
) => <String, dynamic>{
  'scope': instance.scope,
  'new_date': instance.newDate.toIso8601String(),
  'window_start': instance.windowStart,
  'window_end': instance.windowEnd,
  'reason': instance.reason,
  'notify_customer': instance.notifyCustomer,
};
