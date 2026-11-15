// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_delivery_calendar_open_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveryCalendarOpenRequestBody _$AppDeliveryCalendarOpenRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppDeliveryCalendarOpenRequestBody(
  municipalityIds: (json['municipality_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  windows: (json['windows'] as List<dynamic>)
      .map((e) => Windows.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AppDeliveryCalendarOpenRequestBodyToJson(
  AppDeliveryCalendarOpenRequestBody instance,
) => <String, dynamic>{
  'municipality_ids': instance.municipalityIds,
  'from': instance.from.toIso8601String(),
  'to': instance.to.toIso8601String(),
  'weekdays': instance.weekdays,
  'windows': instance.windows,
};
