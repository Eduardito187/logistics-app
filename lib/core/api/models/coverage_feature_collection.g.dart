// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coverage_feature_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoverageFeatureCollection _$CoverageFeatureCollectionFromJson(
  Map<String, dynamic> json,
) => CoverageFeatureCollection(
  type: CoverageFeatureCollectionType.fromJson(json['type'] as String),
  features: (json['features'] as List<dynamic>)
      .map((e) => Features.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CoverageFeatureCollectionToJson(
  CoverageFeatureCollection instance,
) => <String, dynamic>{'type': instance.type, 'features': instance.features};
