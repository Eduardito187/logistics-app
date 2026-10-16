// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxStats _$OutboxStatsFromJson(Map<String, dynamic> json) => OutboxStats(
  pending: (json['pending'] as num).toInt(),
  failed: (json['failed'] as num).toInt(),
  dispatched: (json['dispatched'] as num).toInt(),
  deadLettered: (json['dead_lettered'] as num).toInt(),
  backlog: (json['backlog'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$OutboxStatsToJson(OutboxStats instance) =>
    <String, dynamic>{
      'pending': instance.pending,
      'failed': instance.failed,
      'dispatched': instance.dispatched,
      'dead_lettered': instance.deadLettered,
      'backlog': instance.backlog,
      'total': instance.total,
    };
