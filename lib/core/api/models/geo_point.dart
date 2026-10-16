// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'geo_point.g.dart';

@JsonSerializable()
class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  factory GeoPoint.fromJson(Map<String, Object?> json) =>
      _$GeoPointFromJson(json);

  final double lat;
  final double lng;

  Map<String, Object?> toJson() => _$GeoPointToJson(this);
}
