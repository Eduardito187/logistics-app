// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteGeometry _$RouteGeometryFromJson(Map<String, dynamic> json) =>
    RouteGeometry(
      type: RouteGeometryType.fromJson(json['type'] as String),
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as num).toList())
          .toList(),
      distanceMeters: json['distance_meters'] as num,
      durationSeconds: json['duration_seconds'] as num,
    );

Map<String, dynamic> _$RouteGeometryToJson(RouteGeometry instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
      'distance_meters': instance.distanceMeters,
      'duration_seconds': instance.durationSeconds,
    };
