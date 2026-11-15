// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pre_trip_checklist_result.dart';

part 'post_app_fleet_pre_trip_checklists_response.g.dart';

@JsonSerializable()
class PostAppFleetPreTripChecklistsResponse {
  const PostAppFleetPreTripChecklistsResponse({this.data});

  factory PostAppFleetPreTripChecklistsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppFleetPreTripChecklistsResponseFromJson(json);

  final PreTripChecklistResult? data;

  Map<String, Object?> toJson() =>
      _$PostAppFleetPreTripChecklistsResponseToJson(this);
}
