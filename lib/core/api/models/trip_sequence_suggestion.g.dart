// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_sequence_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripSequenceSuggestion _$TripSequenceSuggestionFromJson(
  Map<String, dynamic> json,
) => TripSequenceSuggestion(
  orderedShipmentIds: (json['ordered_shipment_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => TripSequenceStop.fromJson(e as Map<String, dynamic>))
      .toList(),
  distanceKm: (json['distance_km'] as num).toDouble(),
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  changed: json['changed'] as bool,
  warnings: (json['warnings'] as List<dynamic>)
      .map((e) => TripSequenceWarning.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TripSequenceSuggestionToJson(
  TripSequenceSuggestion instance,
) => <String, dynamic>{
  'ordered_shipment_ids': instance.orderedShipmentIds,
  'stops': instance.stops,
  'distance_km': instance.distanceKm,
  'duration_minutes': instance.durationMinutes,
  'changed': instance.changed,
  'warnings': instance.warnings,
};
