// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_fleet_helpers_helper_id_availability_request_body.g.dart';

@JsonSerializable()
class AppFleetHelpersHelperIdAvailabilityRequestBody {
  const AppFleetHelpersHelperIdAvailabilityRequestBody({required this.active});

  factory AppFleetHelpersHelperIdAvailabilityRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppFleetHelpersHelperIdAvailabilityRequestBodyFromJson(json);

  final bool active;

  Map<String, Object?> toJson() =>
      _$AppFleetHelpersHelperIdAvailabilityRequestBodyToJson(this);
}
