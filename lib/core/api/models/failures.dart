// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'queue.dart';
import 'reason.dart';

part 'failures.g.dart';

@JsonSerializable()
class Failures {
  const Failures({
    required this.id,
    required this.queue,
    required this.kind,
    required this.reason,
    required this.occurredAt,
    this.status,
    this.problemCode,
    this.endpoint,
    this.attempts,
  });

  factory Failures.fromJson(Map<String, Object?> json) =>
      _$FailuresFromJson(json);

  /// Client id of the queued action (idempotency key of the report).
  final String id;
  final Queue queue;
  final String kind;
  final Reason reason;
  final int? status;
  @JsonKey(name: 'problem_code')
  final String? problemCode;

  /// Path only; ids are masked server-side.
  final String? endpoint;
  final int? attempts;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  Map<String, Object?> toJson() => _$FailuresToJson(this);
}
