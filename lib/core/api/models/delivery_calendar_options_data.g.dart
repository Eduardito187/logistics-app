// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_calendar_options_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCalendarOptionsData _$DeliveryCalendarOptionsDataFromJson(
  Map<String, dynamic> json,
) => DeliveryCalendarOptionsData(
  municipalities: (json['municipalities'] as List<dynamic>)
      .map(
        (e) => DeliveryCalendarMunicipality.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  timeSlots: (json['time_slots'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  timeSlotFormat: json['time_slot_format'] as String,
  units: (json['units'] as List<dynamic>)
      .map(
        (e) => DeliveryCalendarUnitOption.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  defaultWindows: (json['default_windows'] as List<dynamic>)
      .map(
        (e) => DeliveryCalendarActivationWindow.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  serviceDays: (json['service_days'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$DeliveryCalendarOptionsDataToJson(
  DeliveryCalendarOptionsData instance,
) => <String, dynamic>{
  'municipalities': instance.municipalities,
  'time_slots': instance.timeSlots,
  'time_slot_format': instance.timeSlotFormat,
  'units': instance.units,
  'default_windows': instance.defaultWindows,
  'weekdays': instance.weekdays,
  'service_days': instance.serviceDays,
};
