// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'promise_offer.g.dart';

@JsonSerializable()
class PromiseOffer {
  const PromiseOffer({
    required this.slotDate,
    required this.weekday,
    required this.timeSlot,
    required this.available,
  });

  factory PromiseOffer.fromJson(Map<String, Object?> json) =>
      _$PromiseOfferFromJson(json);

  @JsonKey(name: 'slot_date')
  final DateTime slotDate;

  /// ISO-8601 weekday (1 = Monday … 7 = Sunday).
  final int weekday;
  @JsonKey(name: 'time_slot')
  final String timeSlot;

  /// Remaining delivery capacity for the slot.
  final double available;

  Map<String, Object?> toJson() => _$PromiseOfferToJson(this);
}
