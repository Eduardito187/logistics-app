// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_block_delivery_slot_data.dart';

part 'post_app_delivery_calendar_blocked_slots_response.g.dart';

@JsonSerializable()
class PostAppDeliveryCalendarBlockedSlotsResponse {
  const PostAppDeliveryCalendarBlockedSlotsResponse({required this.data});

  factory PostAppDeliveryCalendarBlockedSlotsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveryCalendarBlockedSlotsResponseFromJson(json);

  final AppBlockDeliverySlotData data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveryCalendarBlockedSlotsResponseToJson(this);
}
