// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_activation_window_unit.dart';

part 'delivery_calendar_activation_window.g.dart';

@JsonSerializable()
class DeliveryCalendarActivationWindow {
  const DeliveryCalendarActivationWindow({
    required this.timeSlot,
    required this.unit,
    required this.quantity,
  });

  factory DeliveryCalendarActivationWindow.fromJson(
    Map<String, Object?> json,
  ) => _$DeliveryCalendarActivationWindowFromJson(json);

  /// Franja HH:MM-HH:MM
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final DeliveryCalendarActivationWindowUnit unit;
  final num quantity;

  Map<String, Object?> toJson() =>
      _$DeliveryCalendarActivationWindowToJson(this);
}
