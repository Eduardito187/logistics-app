// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'municipality_slot.g.dart';

/// One promisable delivery slot for a customer's municipality. No PII.
@JsonSerializable()
class MunicipalitySlot {
  const MunicipalitySlot({
    required this.municipalityId,
    required this.slotDate,
    required this.timeSlot,
    required this.available,
  });

  factory MunicipalitySlot.fromJson(Map<String, Object?> json) =>
      _$MunicipalitySlotFromJson(json);

  @JsonKey(name: 'municipality_id')
  final String municipalityId;
  @JsonKey(name: 'slot_date')
  final DateTime slotDate;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final num available;

  Map<String, Object?> toJson() => _$MunicipalitySlotToJson(this);
}
