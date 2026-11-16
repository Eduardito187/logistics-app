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
      speedMps: (json['speed_mps'] as num?)?.toDouble(),
      headingDeg: (json['heading_deg'] as num?)?.toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TruckPositionInputToJson(TruckPositionInput instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'reported_at': instance.reportedAt.toIso8601String(),
      'speed_mps': instance.speedMps,
      'heading_deg': instance.headingDeg,
      'accuracy_m': instance.accuracyM,
    };
