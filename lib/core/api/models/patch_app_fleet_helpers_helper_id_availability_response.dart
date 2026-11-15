// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_set_helper_availability_data.dart';

part 'patch_app_fleet_helpers_helper_id_availability_response.g.dart';

@JsonSerializable()
class PatchAppFleetHelpersHelperIdAvailabilityResponse {
  const PatchAppFleetHelpersHelperIdAvailabilityResponse({this.data});

  factory PatchAppFleetHelpersHelperIdAvailabilityResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PatchAppFleetHelpersHelperIdAvailabilityResponseFromJson(json);

  final FleetSetHelperAvailabilityData? data;

  Map<String, Object?> toJson() =>
      _$PatchAppFleetHelpersHelperIdAvailabilityResponseToJson(this);
}
