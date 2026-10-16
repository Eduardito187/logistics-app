// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'available_slot.dart';
import 'meta8.dart';

part 'available_slot_collection.g.dart';

@JsonSerializable()
class AvailableSlotCollection {
  const AvailableSlotCollection({required this.data, required this.meta});

  factory AvailableSlotCollection.fromJson(Map<String, Object?> json) =>
      _$AvailableSlotCollectionFromJson(json);

  final List<AvailableSlot> data;
  final Meta8 meta;

  Map<String, Object?> toJson() => _$AvailableSlotCollectionToJson(this);
}
