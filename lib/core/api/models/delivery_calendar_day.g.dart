// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_calendar_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCalendarDay _$DeliveryCalendarDayFromJson(Map<String, dynamic> json) =>
    DeliveryCalendarDay(
      date: DateTime.parse(json['date'] as String),
      blocked: json['blocked'] as bool,
      reason: json['reason'] as String?,
      slots: (json['slots'] as List<dynamic>)
          .map((e) => DeliveryCalendarSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DeliveryCalendarDayToJson(
  DeliveryCalendarDay instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'blocked': instance.blocked,
  'reason': instance.reason,
  'slots': instance.slots,
};
