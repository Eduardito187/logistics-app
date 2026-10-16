// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coverage_feature_collection_type.dart';
import 'features.dart';

part 'coverage_feature_collection.g.dart';

@JsonSerializable()
class CoverageFeatureCollection {
  const CoverageFeatureCollection({required this.type, required this.features});

  factory CoverageFeatureCollection.fromJson(Map<String, Object?> json) =>
      _$CoverageFeatureCollectionFromJson(json);

  final CoverageFeatureCollectionType type;
  final List<Features> features;

  Map<String, Object?> toJson() => _$CoverageFeatureCollectionToJson(this);
}
