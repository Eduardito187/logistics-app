// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pre_trip_checklist.dart';
import 'collection_meta.dart';

part 'get_app_fleet_pre_trip_checklists_response.g.dart';

@JsonSerializable()
class GetAppFleetPreTripChecklistsResponse {
  const GetAppFleetPreTripChecklistsResponse({this.data, this.meta});

  factory GetAppFleetPreTripChecklistsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetPreTripChecklistsResponseFromJson(json);

  final List<PreTripChecklist>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetAppFleetPreTripChecklistsResponseToJson(this);
}
