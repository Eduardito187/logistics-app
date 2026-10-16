// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'generate_daily_plan_request_strategy.dart';
import 'params.dart';

part 'generate_daily_plan_request.g.dart';

@JsonSerializable()
class GenerateDailyPlanRequest {
  const GenerateDailyPlanRequest({
    required this.planDate,
    required this.strategy,
    this.params,
  });

  factory GenerateDailyPlanRequest.fromJson(Map<String, Object?> json) =>
      _$GenerateDailyPlanRequestFromJson(json);

  /// Day to plan, as YYYY-MM-DD
  @JsonKey(name: 'plan_date')
  final DateTime planDate;

  /// Planning mode. optimization packs by capacity and proximity; slots groups by the customer's chosen delivery time slot.
  final GenerateDailyPlanRequestStrategy strategy;

  /// Optional per-run overrides of the configurable parameters.
  final Params? params;

  Map<String, Object?> toJson() => _$GenerateDailyPlanRequestToJson(this);
}
