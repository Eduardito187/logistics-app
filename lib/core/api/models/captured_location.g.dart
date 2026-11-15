// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captured_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CapturedLocation _$CapturedLocationFromJson(Map<String, dynamic> json) =>
    CapturedLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyM: json['accuracy_m'] as num?,
      capturedAt: json['captured_at'] == null
          ? null
          : DateTime.parse(json['captured_at'] as String),
    );

Map<String, dynamic> _$CapturedLocationToJson(CapturedLocation instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy_m': instance.accuracyM,
      'captured_at': instance.capturedAt?.toIso8601String(),
    };
