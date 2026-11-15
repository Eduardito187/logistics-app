// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
  lat: json['lat'] as num?,
  lng: json['lng'] as num?,
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'recorded_at': instance.recordedAt?.toIso8601String(),
};
