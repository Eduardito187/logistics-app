// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_delivery_calendar_blocked_request_body2.g.dart';

@JsonSerializable()
class AppDeliveryCalendarBlockedRequestBody2 {
  const AppDeliveryCalendarBlockedRequestBody2({
    required this.date,
    this.municipalityId,
  });

  factory AppDeliveryCalendarBlockedRequestBody2.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveryCalendarBlockedRequestBody2FromJson(json);

  final DateTime date;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;

  Map<String, Object?> toJson() =>
      _$AppDeliveryCalendarBlockedRequestBody2ToJson(this);
}
