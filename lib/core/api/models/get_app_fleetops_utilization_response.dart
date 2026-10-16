// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_app_fleetops_utilization_response.g.dart';

@JsonSerializable()
class GetAppFleetopsUtilizationResponse {
  const GetAppFleetopsUtilizationResponse({required this.data});

  factory GetAppFleetopsUtilizationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsUtilizationResponseFromJson(json);

  final dynamic data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsUtilizationResponseToJson(this);
}
