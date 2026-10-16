// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_json_polygon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoJsonPolygon _$GeoJsonPolygonFromJson(Map<String, dynamic> json) =>
    GeoJsonPolygon(
      type: GeoJsonPolygonType.fromJson(json['type'] as String),
      coordinates: (json['coordinates'] as List<dynamic>)
          .map(
            (e) => (e as List<dynamic>)
                .map((e) => (e as List<dynamic>).map((e) => e as num).toList())
                .toList(),
          )
          .toList(),
    );

Map<String, dynamic> _$GeoJsonPolygonToJson(GeoJsonPolygon instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };
