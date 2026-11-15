// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_assemble_crew_data.dart';

part 'post_app_fleet_crews_response.g.dart';

@JsonSerializable()
class PostAppFleetCrewsResponse {
  const PostAppFleetCrewsResponse({this.data});

  factory PostAppFleetCrewsResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppFleetCrewsResponseFromJson(json);

  final FleetAssembleCrewData? data;

  Map<String, Object?> toJson() => _$PostAppFleetCrewsResponseToJson(this);
}
