// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auto_plan_run.dart';

part 'planning_run_updated_event.g.dart';

/// Carga del evento `planning.run.updated` (tema planning): cada cambio de estado de la corrida automática (queued, processing, completed, failed).
@JsonSerializable()
class PlanningRunUpdatedEvent {
  const PlanningRunUpdatedEvent({
    required this.planDate,
    required this.strategy,
    required this.status,
    required this.run,
  });

  factory PlanningRunUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$PlanningRunUpdatedEventFromJson(json);

  @JsonKey(name: 'plan_date')
  final DateTime planDate;
  final String strategy;
  final String status;
  final AutoPlanRun run;

  Map<String, Object?> toJson() => _$PlanningRunUpdatedEventToJson(this);
}
