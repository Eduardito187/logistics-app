// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_candidate_anchor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripCandidateAnchor _$TripCandidateAnchorFromJson(Map<String, dynamic> json) =>
    TripCandidateAnchor(
      kind: TripCandidateAnchorKind.fromJson(json['kind'] as String),
      name: json['name'] as String,
    );

Map<String, dynamic> _$TripCandidateAnchorToJson(
  TripCandidateAnchor instance,
) => <String, dynamic>{'kind': instance.kind, 'name': instance.name};
