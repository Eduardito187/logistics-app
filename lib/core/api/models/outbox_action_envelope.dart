// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data24.dart';

part 'outbox_action_envelope.g.dart';

@JsonSerializable()
class OutboxActionEnvelope {
  const OutboxActionEnvelope({required this.data});

  factory OutboxActionEnvelope.fromJson(Map<String, Object?> json) =>
      _$OutboxActionEnvelopeFromJson(json);

  final Data24 data;

  Map<String, Object?> toJson() => _$OutboxActionEnvelopeToJson(this);
}
