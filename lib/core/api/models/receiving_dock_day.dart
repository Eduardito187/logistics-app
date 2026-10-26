// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'receiving_dock_slot.dart';

part 'receiving_dock_day.g.dart';

@JsonSerializable()
class ReceivingDockDay {
  const ReceivingDockDay({
    required this.date,
    required this.appointments,
    required this.slots,
  });

  factory ReceivingDockDay.fromJson(Map<String, Object?> json) =>
      _$ReceivingDockDayFromJson(json);

  final DateTime date;

  /// Total appointments scheduled for the day.
  final int appointments;
  final List<ReceivingDockSlot> slots;

  Map<String, Object?> toJson() => _$ReceivingDockDayToJson(this);
}
