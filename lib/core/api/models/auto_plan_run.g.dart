// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_plan_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoPlanRun _$AutoPlanRunFromJson(Map<String, dynamic> json) => AutoPlanRun(
  id: json['id'] as String,
  planDate: DateTime.parse(json['plan_date'] as String),
  strategy: AutoPlanRunStrategy.fromJson(json['strategy'] as String),
  status: AutoPlanRunStatus.fromJson(json['status'] as String),
  requestedAt: DateTime.parse(json['requested_at'] as String),
  trucksPlanned: (json['trucks_planned'] as num).toInt(),
  stopsPlanned: (json['stops_planned'] as num).toInt(),
  unassignedCount: (json['unassigned_count'] as num).toInt(),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  failureReason: json['failure_reason'] as String?,
);

Map<String, dynamic> _$AutoPlanRunToJson(AutoPlanRun instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_date': instance.planDate.toIso8601String(),
      'strategy': instance.strategy,
      'status': instance.status,
      'requested_at': instance.requestedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'trucks_planned': instance.trucksPlanned,
      'stops_planned': instance.stopsPlanned,
      'unassigned_count': instance.unassignedCount,
      'failure_reason': instance.failureReason,
    };
