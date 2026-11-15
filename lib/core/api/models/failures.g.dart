// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'failures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Failures _$FailuresFromJson(Map<String, dynamic> json) => Failures(
  id: json['id'] as String,
  queue: Queue.fromJson(json['queue'] as String),
  kind: json['kind'] as String,
  reason: Reason.fromJson(json['reason'] as String),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  status: (json['status'] as num?)?.toInt(),
  problemCode: json['problem_code'] as String?,
  endpoint: json['endpoint'] as String?,
  attempts: (json['attempts'] as num?)?.toInt(),
);

Map<String, dynamic> _$FailuresToJson(Failures instance) => <String, dynamic>{
  'id': instance.id,
  'queue': instance.queue,
  'kind': instance.kind,
  'reason': instance.reason,
  'status': instance.status,
  'problem_code': instance.problemCode,
  'endpoint': instance.endpoint,
  'attempts': instance.attempts,
  'occurred_at': instance.occurredAt.toIso8601String(),
};
