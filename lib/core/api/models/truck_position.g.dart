// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truck_position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TruckPosition _$TruckPositionFromJson(Map<String, dynamic> json) =>
    TruckPosition(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      reportedAt: DateTime.parse(json['reported_at'] as String),
    );

Map<String, dynamic> _$TruckPositionToJson(TruckPosition instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'reported_at': instance.reportedAt.toIso8601String(),
    };
