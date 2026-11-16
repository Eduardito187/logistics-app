// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_slot.dart';

part 'delivery_calendar_day.g.dart';

@JsonSerializable()
class DeliveryCalendarDay {
  const DeliveryCalendarDay({
    required this.date,
    required this.blocked,
    required this.reason,
    required this.slots,
  });

  factory DeliveryCalendarDay.fromJson(Map<String, Object?> json) =>
      _$DeliveryCalendarDayFromJson(json);

  final DateTime date;

  /// Bloqueo de día entero (feriado u otro motivo).
  final bool blocked;
  final String? reason;
  final List<DeliveryCalendarSlot> slots;

  Map<String, Object?> toJson() => _$DeliveryCalendarDayToJson(this);
}
