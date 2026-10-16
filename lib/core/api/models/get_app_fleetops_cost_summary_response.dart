// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_cost_summary.dart';

part 'get_app_fleetops_cost_summary_response.g.dart';

@JsonSerializable()
class GetAppFleetopsCostSummaryResponse {
  const GetAppFleetopsCostSummaryResponse({required this.data});

  factory GetAppFleetopsCostSummaryResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsCostSummaryResponseFromJson(json);

  final VehicleCostSummary data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsCostSummaryResponseToJson(this);
}
