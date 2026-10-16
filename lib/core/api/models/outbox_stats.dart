// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'outbox_stats.g.dart';

@JsonSerializable()
class OutboxStats {
  const OutboxStats({
    required this.pending,
    required this.failed,
    required this.dispatched,
    required this.deadLettered,
    required this.backlog,
    required this.total,
  });

  factory OutboxStats.fromJson(Map<String, Object?> json) =>
      _$OutboxStatsFromJson(json);

  final int pending;
  final int failed;
  final int dispatched;
  @JsonKey(name: 'dead_lettered')
  final int deadLettered;

  /// Live queue (pending + failed).
  final int backlog;
  final int total;

  Map<String, Object?> toJson() => _$OutboxStatsToJson(this);
}
