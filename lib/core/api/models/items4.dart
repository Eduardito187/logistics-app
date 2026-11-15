// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'kind.dart';

part 'items4.g.dart';

@JsonSerializable()
class Items4 {
  const Items4({
    required this.idempotencyKey,
    required this.kind,
    required this.occurredAt,
    required this.payload,
  });

  factory Items4.fromJson(Map<String, Object?> json) => _$Items4FromJson(json);

  @JsonKey(name: 'idempotency_key')
  final String idempotencyKey;
  final Kind kind;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  /// Same body as the single endpoint of that kind.
  final dynamic payload;

  Map<String, Object?> toJson() => _$Items4ToJson(this);
}
