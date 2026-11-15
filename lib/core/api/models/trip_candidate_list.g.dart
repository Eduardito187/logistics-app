// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_candidate_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripCandidateList _$TripCandidateListFromJson(Map<String, dynamic> json) =>
    TripCandidateList(
      data: (json['data'] as List<dynamic>)
          .map((e) => TripCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TripCandidateListToJson(TripCandidateList instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
