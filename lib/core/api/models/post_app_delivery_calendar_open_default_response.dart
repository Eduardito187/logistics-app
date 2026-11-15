// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'open_delivery_slots_with_defaults_data.dart';

part 'post_app_delivery_calendar_open_default_response.g.dart';

@JsonSerializable()
class PostAppDeliveryCalendarOpenDefaultResponse {
  const PostAppDeliveryCalendarOpenDefaultResponse({required this.data});

  factory PostAppDeliveryCalendarOpenDefaultResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveryCalendarOpenDefaultResponseFromJson(json);

  final OpenDeliverySlotsWithDefaultsData data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveryCalendarOpenDefaultResponseToJson(this);
}
