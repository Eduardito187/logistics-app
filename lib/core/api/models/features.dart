// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type2.dart';
import 'geo_json_polygon.dart';

part 'features.g.dart';

@JsonSerializable()
class Features {
  const Features({
    required this.type,
    required this.geometry,
    required this.properties,
  });

  factory Features.fromJson(Map<String, Object?> json) =>
      _$FeaturesFromJson(json);

  final Type2 type;
  final GeoJsonPolygon geometry;

  /// Nombre de la zona, área padre y reglas en forma primitiva.
  final dynamic properties;

  Map<String, Object?> toJson() => _$FeaturesToJson(this);
}
