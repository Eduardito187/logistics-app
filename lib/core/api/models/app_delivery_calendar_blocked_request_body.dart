// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_delivery_calendar_blocked_request_body.g.dart';

@JsonSerializable()
class AppDeliveryCalendarBlockedRequestBody {
  const AppDeliveryCalendarBlockedRequestBody({
    required this.date,
    required this.reason,
    this.municipalityId,
  });

  factory AppDeliveryCalendarBlockedRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveryCalendarBlockedRequestBodyFromJson(json);

  final DateTime date;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final String reason;

  Map<String, Object?> toJson() =>
      _$AppDeliveryCalendarBlockedRequestBodyToJson(this);
}
