// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_stats_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxStatsEnvelope _$OutboxStatsEnvelopeFromJson(Map<String, dynamic> json) =>
    OutboxStatsEnvelope(
      data: OutboxStats.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OutboxStatsEnvelopeToJson(
  OutboxStatsEnvelope instance,
) => <String, dynamic>{'data': instance.data};
