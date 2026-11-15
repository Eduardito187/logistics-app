// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_failures_accepted_data.dart';

part 'outbox_failures_accepted.g.dart';

@JsonSerializable()
class OutboxFailuresAccepted {
  const OutboxFailuresAccepted({required this.data});

  factory OutboxFailuresAccepted.fromJson(Map<String, Object?> json) =>
      _$OutboxFailuresAcceptedFromJson(json);

  final OutboxFailuresAcceptedData data;

  Map<String, Object?> toJson() => _$OutboxFailuresAcceptedToJson(this);
}
