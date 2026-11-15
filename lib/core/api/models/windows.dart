// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'windows.g.dart';

@JsonSerializable()
class Windows {
  const Windows({
    required this.timeSlot,
    required this.unit,
    required this.quantity,
  });

  factory Windows.fromJson(Map<String, Object?> json) =>
      _$WindowsFromJson(json);

  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final String unit;
  final num quantity;

  Map<String, Object?> toJson() => _$WindowsToJson(this);
}
