// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_message.dart';

part 'outbox_message_envelope.g.dart';

@JsonSerializable()
class OutboxMessageEnvelope {
  const OutboxMessageEnvelope({required this.data});

  factory OutboxMessageEnvelope.fromJson(Map<String, Object?> json) =>
      _$OutboxMessageEnvelopeFromJson(json);

  final OutboxMessage data;

  Map<String, Object?> toJson() => _$OutboxMessageEnvelopeToJson(this);
}
