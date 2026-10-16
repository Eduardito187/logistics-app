// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Features _$FeaturesFromJson(Map<String, dynamic> json) => Features(
  type: Type2.fromJson(json['type'] as String),
  geometry: GeoJsonPolygon.fromJson(json['geometry'] as Map<String, dynamic>),
  properties: json['properties'],
);

Map<String, dynamic> _$FeaturesToJson(Features instance) => <String, dynamic>{
  'type': instance.type,
  'geometry': instance.geometry,
  'properties': instance.properties,
};
