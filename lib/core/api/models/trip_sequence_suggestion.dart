// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip_sequence_stop.dart';
import 'trip_sequence_warning.dart';

part 'trip_sequence_suggestion.g.dart';

@JsonSerializable()
class TripSequenceSuggestion {
  const TripSequenceSuggestion({
    required this.orderedShipmentIds,
    required this.stops,
    required this.distanceKm,
    required this.durationMinutes,
    required this.changed,
    required this.warnings,
  });

  factory TripSequenceSuggestion.fromJson(Map<String, Object?> json) =>
      _$TripSequenceSuggestionFromJson(json);

  @JsonKey(name: 'ordered_shipment_ids')
  final List<String> orderedShipmentIds;
  final List<TripSequenceStop> stops;
  @JsonKey(name: 'distance_km')
  final double distanceKm;

  /// From departure to the end of the last delivery, service time included.
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final bool changed;
  final List<TripSequenceWarning> warnings;

  Map<String, Object?> toJson() => _$TripSequenceSuggestionToJson(this);
}
