// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'my_crew.dart';

part 'get_app_fleet_my_crew_response.g.dart';

@JsonSerializable()
class GetAppFleetMyCrewResponse {
  const GetAppFleetMyCrewResponse({this.data});

  factory GetAppFleetMyCrewResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetMyCrewResponseFromJson(json);

  final MyCrew? data;

  Map<String, Object?> toJson() => _$GetAppFleetMyCrewResponseToJson(this);
}
