// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_run_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanningRunUpdatedEvent _$PlanningRunUpdatedEventFromJson(
  Map<String, dynamic> json,
) => PlanningRunUpdatedEvent(
  planDate: DateTime.parse(json['plan_date'] as String),
  strategy: json['strategy'] as String,
  status: json['status'] as String,
  run: AutoPlanRun.fromJson(json['run'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlanningRunUpdatedEventToJson(
  PlanningRunUpdatedEvent instance,
) => <String, dynamic>{
  'plan_date': instance.planDate.toIso8601String(),
  'strategy': instance.strategy,
  'status': instance.status,
  'run': instance.run,
};
