// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'helper.dart';
import 'collection_meta.dart';

part 'get_app_fleet_helpers_response.g.dart';

@JsonSerializable()
class GetAppFleetHelpersResponse {
  const GetAppFleetHelpersResponse({this.data, this.meta});

  factory GetAppFleetHelpersResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetHelpersResponseFromJson(json);

  final List<Helper>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() => _$GetAppFleetHelpersResponseToJson(this);
}
