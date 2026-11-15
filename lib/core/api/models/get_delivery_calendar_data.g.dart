// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_delivery_calendar_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDeliveryCalendarData _$GetDeliveryCalendarDataFromJson(
  Map<String, dynamic> json,
) => GetDeliveryCalendarData(
  from: json['from'] == null ? null : DateTime.parse(json['from'] as String),
  to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
  municipalityId: json['municipality_id'] as String?,
  days: (json['days'] as List<dynamic>?)
      ?.map((e) => Days.fromJson(e as Map<String, dynamic>))
      .toList(),
  blocked: json['blocked'] as List<dynamic>?,
);

Map<String, dynamic> _$GetDeliveryCalendarDataToJson(
  GetDeliveryCalendarData instance,
) => <String, dynamic>{
  'from': instance.from?.toIso8601String(),
  'to': instance.to?.toIso8601String(),
  'municipality_id': instance.municipalityId,
  'days': instance.days,
  'blocked': instance.blocked,
};
