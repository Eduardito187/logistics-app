// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data4.dart';

part 'patch_app_fleet_helpers_helper_id_availability_response.g.dart';

@JsonSerializable()
class PatchAppFleetHelpersHelperIdAvailabilityResponse {
  const PatchAppFleetHelpersHelperIdAvailabilityResponse({this.data});

  factory PatchAppFleetHelpersHelperIdAvailabilityResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PatchAppFleetHelpersHelperIdAvailabilityResponseFromJson(json);

  final Data4? data;

  Map<String, Object?> toJson() =>
      _$PatchAppFleetHelpersHelperIdAvailabilityResponseToJson(this);
}
