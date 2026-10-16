// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'leg.dart';

part 'leg_envelope.g.dart';

@JsonSerializable()
class LegEnvelope {
  const LegEnvelope({required this.data});

  factory LegEnvelope.fromJson(Map<String, Object?> json) =>
      _$LegEnvelopeFromJson(json);

  final Leg data;

  Map<String, Object?> toJson() => _$LegEnvelopeToJson(this);
}
