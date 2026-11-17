// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_delivery_calendar_blocked_slots_request_body2.g.dart';

@JsonSerializable()
class AppDeliveryCalendarBlockedSlotsRequestBody2 {
  const AppDeliveryCalendarBlockedSlotsRequestBody2({
    required this.date,
    required this.timeSlot,
    this.municipalityId,
  });

  factory AppDeliveryCalendarBlockedSlotsRequestBody2.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveryCalendarBlockedSlotsRequestBody2FromJson(json);

  final DateTime date;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;

  Map<String, Object?> toJson() =>
      _$AppDeliveryCalendarBlockedSlotsRequestBody2ToJson(this);
}
