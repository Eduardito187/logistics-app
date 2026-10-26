// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'receiving_dock_slot.g.dart';

@JsonSerializable()
class ReceivingDockSlot {
  const ReceivingDockSlot({required this.timeSlot, required this.appointments});

  factory ReceivingDockSlot.fromJson(Map<String, Object?> json) =>
      _$ReceivingDockSlotFromJson(json);

  /// Time slot as HH:MM-HH:MM.
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final int appointments;

  Map<String, Object?> toJson() => _$ReceivingDockSlotToJson(this);
}
