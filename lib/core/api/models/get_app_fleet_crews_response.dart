// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_list_crews_item.dart';
import 'list_meta.dart';

part 'get_app_fleet_crews_response.g.dart';

@JsonSerializable()
class GetAppFleetCrewsResponse {
  const GetAppFleetCrewsResponse({required this.data, required this.meta});

  factory GetAppFleetCrewsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetCrewsResponseFromJson(json);

  final List<FleetListCrewsItem> data;
  final ListMeta meta;

  Map<String, Object?> toJson() => _$GetAppFleetCrewsResponseToJson(this);
}
