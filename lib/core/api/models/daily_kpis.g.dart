// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_kpis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyKpis _$DailyKpisFromJson(Map<String, dynamic> json) => DailyKpis(
  date: DateTime.parse(json['date'] as String),
  scope: DailyKpisScope.fromJson(json['scope'] as String),
  deliveriesTotal: (json['deliveries_total'] as num).toInt(),
  delivered: (json['delivered'] as num).toInt(),
  failed: (json['failed'] as num).toInt(),
  rescheduled: (json['rescheduled'] as num).toInt(),
  pending: (json['pending'] as num).toInt(),
  onTimeRate: json['on_time_rate'] as num?,
  firstAttemptSuccessRate: json['first_attempt_success_rate'] as num?,
  avgStopMinutes: json['avg_stop_minutes'] as num?,
  km: (json['km'] as num?)?.toInt(),
  failedByReason: (json['failed_by_reason'] as List<dynamic>)
      .map((e) => FailedByReason.fromJson(e as Map<String, dynamic>))
      .toList(),
  generatedAt: DateTime.parse(json['generated_at'] as String),
);

Map<String, dynamic> _$DailyKpisToJson(DailyKpis instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'scope': instance.scope,
  'deliveries_total': instance.deliveriesTotal,
  'delivered': instance.delivered,
  'failed': instance.failed,
  'rescheduled': instance.rescheduled,
  'pending': instance.pending,
  'on_time_rate': instance.onTimeRate,
  'first_attempt_success_rate': instance.firstAttemptSuccessRate,
  'avg_stop_minutes': instance.avgStopMinutes,
  'km': instance.km,
  'failed_by_reason': instance.failedByReason,
  'generated_at': instance.generatedAt.toIso8601String(),
};
