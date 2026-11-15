// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip_candidate_anchor_kind.dart';

part 'trip_candidate_anchor.g.dart';

/// Point the distance was measured from.
@JsonSerializable()
class TripCandidateAnchor {
  const TripCandidateAnchor({required this.kind, required this.name});

  factory TripCandidateAnchor.fromJson(Map<String, Object?> json) =>
      _$TripCandidateAnchorFromJson(json);

  final TripCandidateAnchorKind kind;
  final String name;

  Map<String, Object?> toJson() => _$TripCandidateAnchorToJson(this);
}
