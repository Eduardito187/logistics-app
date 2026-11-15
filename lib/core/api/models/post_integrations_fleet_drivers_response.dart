// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_register_driver_data.dart';

part 'post_integrations_fleet_drivers_response.g.dart';

@JsonSerializable()
class PostIntegrationsFleetDriversResponse {
  const PostIntegrationsFleetDriversResponse({this.data});

  factory PostIntegrationsFleetDriversResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsFleetDriversResponseFromJson(json);

  final FleetRegisterDriverData? data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsFleetDriversResponseToJson(this);
}
