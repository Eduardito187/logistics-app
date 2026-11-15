// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Points _$PointsFromJson(Map<String, dynamic> json) => Points(
  lat: json['lat'] as num?,
  lng: json['lng'] as num?,
  speedKph: json['speed_kph'] as num?,
  heading: (json['heading'] as num?)?.toInt(),
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$PointsToJson(Points instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'speed_kph': instance.speedKph,
  'heading': instance.heading,
  'recorded_at': instance.recordedAt?.toIso8601String(),
};
