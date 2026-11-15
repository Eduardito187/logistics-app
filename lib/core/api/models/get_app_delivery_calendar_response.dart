// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'get_delivery_calendar_data.dart';

part 'get_app_delivery_calendar_response.g.dart';

@JsonSerializable()
class GetAppDeliveryCalendarResponse {
  const GetAppDeliveryCalendarResponse({this.data});

  factory GetAppDeliveryCalendarResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppDeliveryCalendarResponseFromJson(json);

  final GetDeliveryCalendarData? data;

  Map<String, Object?> toJson() => _$GetAppDeliveryCalendarResponseToJson(this);
}
