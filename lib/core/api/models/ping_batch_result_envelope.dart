// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ping_batch_result_envelope_data.dart';

part 'ping_batch_result_envelope.g.dart';

@JsonSerializable()
class PingBatchResultEnvelope {
  const PingBatchResultEnvelope({required this.data});

  factory PingBatchResultEnvelope.fromJson(Map<String, Object?> json) =>
      _$PingBatchResultEnvelopeFromJson(json);

  final PingBatchResultEnvelopeData data;

  Map<String, Object?> toJson() => _$PingBatchResultEnvelopeToJson(this);
}
