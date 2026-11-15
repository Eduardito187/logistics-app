// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'list_meta.dart';
import 'trip_candidate.dart';

part 'trip_candidate_list.g.dart';

@JsonSerializable()
class TripCandidateList {
  const TripCandidateList({required this.data, required this.meta});

  factory TripCandidateList.fromJson(Map<String, Object?> json) =>
      _$TripCandidateListFromJson(json);

  final List<TripCandidate> data;
  final ListMeta meta;

  Map<String, Object?> toJson() => _$TripCandidateListToJson(this);
}
