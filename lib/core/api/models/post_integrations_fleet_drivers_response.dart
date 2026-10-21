// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data16.dart';

part 'post_integrations_fleet_drivers_response.g.dart';

@JsonSerializable()
class PostIntegrationsFleetDriversResponse {
  const PostIntegrationsFleetDriversResponse({this.data});

  factory PostIntegrationsFleetDriversResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsFleetDriversResponseFromJson(json);

  final Data16? data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsFleetDriversResponseToJson(this);
}
