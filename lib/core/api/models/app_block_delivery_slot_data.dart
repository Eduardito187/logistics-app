// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_block_delivery_slot_data.g.dart';

@JsonSerializable()
class AppBlockDeliverySlotData {
  const AppBlockDeliverySlotData({
    this.status,
    this.date,
    this.timeSlot,
    this.municipalityId,
    this.blocked,
  });

  factory AppBlockDeliverySlotData.fromJson(Map<String, Object?> json) =>
      _$AppBlockDeliverySlotDataFromJson(json);

  final String? status;
  final DateTime? date;
  @JsonKey(name: 'time_slot')
  final String? timeSlot;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final bool? blocked;

  Map<String, Object?> toJson() => _$AppBlockDeliverySlotDataToJson(this);
}
