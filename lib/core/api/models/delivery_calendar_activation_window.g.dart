// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_calendar_activation_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCalendarActivationWindow _$DeliveryCalendarActivationWindowFromJson(
  Map<String, dynamic> json,
) => DeliveryCalendarActivationWindow(
  timeSlot: json['time_slot'] as String,
  unit: DeliveryCalendarActivationWindowUnit.fromJson(json['unit'] as String),
  quantity: json['quantity'] as num,
);

Map<String, dynamic> _$DeliveryCalendarActivationWindowToJson(
  DeliveryCalendarActivationWindow instance,
) => <String, dynamic>{
  'time_slot': instance.timeSlot,
  'unit': instance.unit,
  'quantity': instance.quantity,
};
