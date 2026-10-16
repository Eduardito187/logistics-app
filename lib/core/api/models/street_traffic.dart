// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geo_point.dart';
import 'street_traffic_congestion_level.dart';

part 'street_traffic.g.dart';

/// Estadística agregada de un segmento de calle para el mapa de tráfico.
@JsonSerializable()
class StreetTraffic {
  const StreetTraffic({
    required this.segmentKey,
    required this.geometry,
    required this.sampleCount,
    required this.avgSpeedKph,
    required this.minSpeedKph,
    required this.congestionLevel,
    required this.hourHistogram,
    this.name,
  });

  factory StreetTraffic.fromJson(Map<String, Object?> json) =>
      _$StreetTrafficFromJson(json);

  @JsonKey(name: 'segment_key')
  final String segmentKey;
  final String? name;
  final List<GeoPoint> geometry;
  @JsonKey(name: 'sample_count')
  final int sampleCount;
  @JsonKey(name: 'avg_speed_kph')
  final double avgSpeedKph;
  @JsonKey(name: 'min_speed_kph')
  final double minSpeedKph;
  @JsonKey(name: 'congestion_level')
  final StreetTrafficCongestionLevel congestionLevel;
  @JsonKey(name: 'hour_histogram')
  final List<int> hourHistogram;

  Map<String, Object?> toJson() => _$StreetTrafficToJson(this);
}
