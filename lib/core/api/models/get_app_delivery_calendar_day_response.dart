// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_day.dart';

part 'get_app_delivery_calendar_day_response.g.dart';

@JsonSerializable()
class GetAppDeliveryCalendarDayResponse {
  const GetAppDeliveryCalendarDayResponse({required this.data});

  factory GetAppDeliveryCalendarDayResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppDeliveryCalendarDayResponseFromJson(json);

  final DeliveryCalendarDay data;

  Map<String, Object?> toJson() =>
      _$GetAppDeliveryCalendarDayResponseToJson(this);
}
