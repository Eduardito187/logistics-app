// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pre_trip_checklist.dart';

part 'get_app_fleet_pre_trip_checklists_latest_response.g.dart';

@JsonSerializable()
class GetAppFleetPreTripChecklistsLatestResponse {
  const GetAppFleetPreTripChecklistsLatestResponse({required this.data});

  factory GetAppFleetPreTripChecklistsLatestResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetPreTripChecklistsLatestResponseFromJson(json);

  final PreTripChecklist data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetPreTripChecklistsLatestResponseToJson(this);
}
