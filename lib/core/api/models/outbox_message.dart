// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_status.dart';

part 'outbox_message.g.dart';

@JsonSerializable()
class OutboxMessage {
  const OutboxMessage({
    required this.id,
    required this.eventId,
    required this.aggregateType,
    required this.aggregateId,
    required this.eventName,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.availableAt,
    required this.createdAt,
    this.dispatchedAt,
    this.lastError,
  });

  factory OutboxMessage.fromJson(Map<String, Object?> json) =>
      _$OutboxMessageFromJson(json);

  final String id;

  /// Idempotency key; appending the same event twice is a no-op.
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'aggregate_type')
  final String aggregateType;
  @JsonKey(name: 'aggregate_id')
  final String aggregateId;
  @JsonKey(name: 'event_name')
  final String eventName;
  final dynamic payload;
  final OutboxStatus status;
  final int attempts;
  @JsonKey(name: 'available_at')
  final DateTime availableAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'dispatched_at')
  final DateTime? dispatchedAt;
  @JsonKey(name: 'last_error')
  final String? lastError;

  Map<String, Object?> toJson() => _$OutboxMessageToJson(this);
}
