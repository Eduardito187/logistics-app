// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_arrived_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StopArrivedRequest _$StopArrivedRequestFromJson(Map<String, dynamic> json) =>
    StopArrivedRequest(
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      source: StopArrivedRequestSource.fromJson(json['source'] as String),
      lat: json['lat'] as num?,
      lng: json['lng'] as num?,
      accuracyM: json['accuracy_m'] as num?,
    );

Map<String, dynamic> _$StopArrivedRequestToJson(StopArrivedRequest instance) =>
    <String, dynamic>{
      'occurred_at': instance.occurredAt.toIso8601String(),
      'source': instance.source,
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy_m': instance.accuracyM,
    };
