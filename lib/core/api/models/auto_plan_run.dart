// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auto_plan_run_status.dart';
import 'auto_plan_run_strategy.dart';

part 'auto_plan_run.g.dart';

@JsonSerializable()
class AutoPlanRun {
  const AutoPlanRun({
    required this.id,
    required this.planDate,
    required this.strategy,
    required this.status,
    required this.requestedAt,
    required this.trucksPlanned,
    required this.stopsPlanned,
    required this.unassignedCount,
    this.completedAt,
    this.failureReason,
  });

  factory AutoPlanRun.fromJson(Map<String, Object?> json) =>
      _$AutoPlanRunFromJson(json);

  final String id;
  @JsonKey(name: 'plan_date')
  final DateTime planDate;
  final AutoPlanRunStrategy strategy;

  /// Lifecycle of the asynchronous run
  final AutoPlanRunStatus status;
  @JsonKey(name: 'requested_at')
  final DateTime requestedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'trucks_planned')
  final int trucksPlanned;
  @JsonKey(name: 'stops_planned')
  final int stopsPlanned;
  @JsonKey(name: 'unassigned_count')
  final int unassignedCount;
  @JsonKey(name: 'failure_reason')
  final String? failureReason;

  Map<String, Object?> toJson() => _$AutoPlanRunToJson(this);
}
