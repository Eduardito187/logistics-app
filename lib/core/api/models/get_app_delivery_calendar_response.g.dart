// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_delivery_calendar_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppDeliveryCalendarResponse _$GetAppDeliveryCalendarResponseFromJson(
  Map<String, dynamic> json,
) => GetAppDeliveryCalendarResponse(
  data: json['data'] == null
      ? null
      : GetDeliveryCalendarData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppDeliveryCalendarResponseToJson(
  GetAppDeliveryCalendarResponse instance,
) => <String, dynamic>{'data': instance.data};
