// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'points.g.dart';

@JsonSerializable()
class Points {
  const Points({
    this.lat,
    this.lng,
    this.speedKph,
    this.heading,
    this.recordedAt,
  });

  factory Points.fromJson(Map<String, Object?> json) => _$PointsFromJson(json);

  final num? lat;
  final num? lng;
  @JsonKey(name: 'speed_kph')
  final num? speedKph;
  final int? heading;
  @JsonKey(name: 'recorded_at')
  final DateTime? recordedAt;

  Map<String, Object?> toJson() => _$PointsToJson(this);
}
