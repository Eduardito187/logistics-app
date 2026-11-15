// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable()
class Position {
  const Position({this.lat, this.lng, this.recordedAt});

  factory Position.fromJson(Map<String, Object?> json) =>
      _$PositionFromJson(json);

  final num? lat;
  final num? lng;
  @JsonKey(name: 'recorded_at')
  final DateTime? recordedAt;

  Map<String, Object?> toJson() => _$PositionToJson(this);
}
