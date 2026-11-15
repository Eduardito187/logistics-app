// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_status.dart';

part 'outbox_action_envelope_data.g.dart';

@JsonSerializable()
class OutboxActionEnvelopeData {
  const OutboxActionEnvelopeData({required this.id, required this.status});

  factory OutboxActionEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$OutboxActionEnvelopeDataFromJson(json);

  final String id;
  final OutboxStatus status;

  Map<String, Object?> toJson() => _$OutboxActionEnvelopeDataToJson(this);
}
