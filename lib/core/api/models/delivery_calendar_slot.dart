// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_slot_unit.dart';

part 'delivery_calendar_slot.g.dart';

@JsonSerializable()
class DeliveryCalendarSlot {
  const DeliveryCalendarSlot({
    required this.timeSlot,
    required this.capacity,
    required this.used,
    required this.unit,
    required this.blocked,
    required this.reason,
  });

  factory DeliveryCalendarSlot.fromJson(Map<String, Object?> json) =>
      _$DeliveryCalendarSlotFromJson(json);

  @JsonKey(name: 'time_slot')
  final String timeSlot;

  /// Cupo definido; null si no hay bucket para la franja.
  final num? capacity;
  final num used;
  final DeliveryCalendarSlotUnit unit;

  /// true si la franja está bloqueada o lo está el día entero.
  final bool blocked;
  final String? reason;

  Map<String, Object?> toJson() => _$DeliveryCalendarSlotToJson(this);
}
