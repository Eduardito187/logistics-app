// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'route_geometry_type.dart';

part 'route_geometry.g.dart';

/// GeoJSON LineString of the planned route along streets, plus the total distance and duration of the trip.
@JsonSerializable()
class RouteGeometry {
  const RouteGeometry({
    required this.type,
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteGeometry.fromJson(Map<String, Object?> json) =>
      _$RouteGeometryFromJson(json);

  final RouteGeometryType type;

  /// Ordered [lng, lat] pairs along the route.
  final List<List<num>> coordinates;

  /// Total route distance in meters.
  @JsonKey(name: 'distance_meters')
  final num distanceMeters;

  /// Total route duration in seconds.
  @JsonKey(name: 'duration_seconds')
  final num durationSeconds;

  Map<String, Object?> toJson() => _$RouteGeometryToJson(this);
}
