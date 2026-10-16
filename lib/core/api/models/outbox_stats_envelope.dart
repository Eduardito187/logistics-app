// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_stats.dart';

part 'outbox_stats_envelope.g.dart';

@JsonSerializable()
class OutboxStatsEnvelope {
  const OutboxStatsEnvelope({required this.data});

  factory OutboxStatsEnvelope.fromJson(Map<String, Object?> json) =>
      _$OutboxStatsEnvelopeFromJson(json);

  final OutboxStats data;

  Map<String, Object?> toJson() => _$OutboxStatsEnvelopeToJson(this);
}
