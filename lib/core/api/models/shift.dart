// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shift.g.dart';

@JsonSerializable()
class Shift {
  const Shift({required this.startsAt, required this.endsAt});

  factory Shift.fromJson(Map<String, Object?> json) => _$ShiftFromJson(json);

  @JsonKey(name: 'starts_at')
  final DateTime startsAt;
  @JsonKey(name: 'ends_at')
  final DateTime endsAt;

  Map<String, Object?> toJson() => _$ShiftToJson(this);
}
