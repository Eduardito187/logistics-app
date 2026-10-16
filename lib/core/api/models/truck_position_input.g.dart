// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truck_position_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TruckPositionInput _$TruckPositionInputFromJson(Map<String, dynamic> json) =>
    TruckPositionInput(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      reportedAt: DateTime.parse(json['reported_at'] as String),
    );

Map<String, dynamic> _$TruckPositionInputToJson(TruckPositionInput instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'reported_at': instance.reportedAt.toIso8601String(),
    };
