// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'available_slot.g.dart';

@JsonSerializable()
class AvailableSlot {
  const AvailableSlot({required this.slotDate, required this.timeSlot});

  factory AvailableSlot.fromJson(Map<String, Object?> json) =>
      _$AvailableSlotFromJson(json);

  @JsonKey(name: 'slot_date')
  final DateTime slotDate;
  @JsonKey(name: 'time_slot')
  final String timeSlot;

  Map<String, Object?> toJson() => _$AvailableSlotToJson(this);
}
