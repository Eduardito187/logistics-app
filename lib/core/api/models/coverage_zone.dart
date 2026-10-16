// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coverage_rule.dart';
import 'geo_json_polygon.dart';

part 'coverage_zone.g.dart';

@JsonSerializable()
class CoverageZone {
  const CoverageZone({
    required this.id,
    required this.name,
    required this.parentAreaId,
    required this.active,
    required this.polygon,
    required this.rules,
  });

  factory CoverageZone.fromJson(Map<String, Object?> json) =>
      _$CoverageZoneFromJson(json);

  final String id;
  final String name;
  final String? parentAreaId;
  final bool active;
  final GeoJsonPolygon polygon;
  final CoverageRule rules;

  Map<String, Object?> toJson() => _$CoverageZoneToJson(this);
}
