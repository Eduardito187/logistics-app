// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_delivery_calendar_blocked_slots_request_body.g.dart';

@JsonSerializable()
class AppDeliveryCalendarBlockedSlotsRequestBody {
  const AppDeliveryCalendarBlockedSlotsRequestBody({
    required this.date,
    required this.timeSlot,
    required this.reason,
    this.municipalityId,
  });

  factory AppDeliveryCalendarBlockedSlotsRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveryCalendarBlockedSlotsRequestBodyFromJson(json);

  final DateTime date;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final String reason;

  /// null = bloqueo global de la franja (todas las tiendas).
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;

  Map<String, Object?> toJson() =>
      _$AppDeliveryCalendarBlockedSlotsRequestBodyToJson(this);
}
