// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geo_json_polygon_type.dart';

part 'geo_json_polygon.g.dart';

@JsonSerializable()
class GeoJsonPolygon {
  const GeoJsonPolygon({required this.type, required this.coordinates});

  factory GeoJsonPolygon.fromJson(Map<String, Object?> json) =>
      _$GeoJsonPolygonFromJson(json);

  final GeoJsonPolygonType type;

  /// Anillos del polígono; cada posición es un par [lng, lat].
  final List<List<List<num>>> coordinates;

  Map<String, Object?> toJson() => _$GeoJsonPolygonToJson(this);
}
