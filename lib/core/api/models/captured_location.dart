// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'captured_location.g.dart';

/// Optional device location; (0,0) is treated as no position.
@JsonSerializable()
class CapturedLocation {
  const CapturedLocation({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.capturedAt,
  });

  factory CapturedLocation.fromJson(Map<String, Object?> json) =>
      _$CapturedLocationFromJson(json);

  final double lat;
  final double lng;
  @JsonKey(name: 'accuracy_m')
  final num? accuracyM;
  @JsonKey(name: 'captured_at')
  final DateTime? capturedAt;

  Map<String, Object?> toJson() => _$CapturedLocationToJson(this);
}
