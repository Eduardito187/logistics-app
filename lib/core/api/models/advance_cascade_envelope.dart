// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data23.dart';

part 'advance_cascade_envelope.g.dart';

@JsonSerializable()
class AdvanceCascadeEnvelope {
  const AdvanceCascadeEnvelope({required this.data});

  factory AdvanceCascadeEnvelope.fromJson(Map<String, Object?> json) =>
      _$AdvanceCascadeEnvelopeFromJson(json);

  final Data23 data;

  Map<String, Object?> toJson() => _$AdvanceCascadeEnvelopeToJson(this);
}
