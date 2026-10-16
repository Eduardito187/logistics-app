// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'relay_outbox_result.dart';

part 'relay_outbox_result_envelope.g.dart';

@JsonSerializable()
class RelayOutboxResultEnvelope {
  const RelayOutboxResultEnvelope({required this.data});

  factory RelayOutboxResultEnvelope.fromJson(Map<String, Object?> json) =>
      _$RelayOutboxResultEnvelopeFromJson(json);

  final RelayOutboxResult data;

  Map<String, Object?> toJson() => _$RelayOutboxResultEnvelopeToJson(this);
}
