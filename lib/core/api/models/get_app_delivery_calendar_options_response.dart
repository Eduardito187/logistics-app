// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_options_data.dart';

part 'get_app_delivery_calendar_options_response.g.dart';

@JsonSerializable()
class GetAppDeliveryCalendarOptionsResponse {
  const GetAppDeliveryCalendarOptionsResponse({required this.data});

  factory GetAppDeliveryCalendarOptionsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppDeliveryCalendarOptionsResponseFromJson(json);

  final DeliveryCalendarOptionsData data;

  Map<String, Object?> toJson() =>
      _$GetAppDeliveryCalendarOptionsResponseToJson(this);
}
