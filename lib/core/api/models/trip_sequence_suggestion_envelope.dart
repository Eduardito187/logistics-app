// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip_sequence_suggestion.dart';

part 'trip_sequence_suggestion_envelope.g.dart';

@JsonSerializable()
class TripSequenceSuggestionEnvelope {
  const TripSequenceSuggestionEnvelope({required this.data});

  factory TripSequenceSuggestionEnvelope.fromJson(Map<String, Object?> json) =>
      _$TripSequenceSuggestionEnvelopeFromJson(json);

  final TripSequenceSuggestion data;

  Map<String, Object?> toJson() => _$TripSequenceSuggestionEnvelopeToJson(this);
}
