// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data18.dart';

part 'post_integrations_fleet_vehicles_response.g.dart';

@JsonSerializable()
class PostIntegrationsFleetVehiclesResponse {
  const PostIntegrationsFleetVehiclesResponse({this.data});

  factory PostIntegrationsFleetVehiclesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsFleetVehiclesResponseFromJson(json);

  final Data18? data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsFleetVehiclesResponseToJson(this);
}
