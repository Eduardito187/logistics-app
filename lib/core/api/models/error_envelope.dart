// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error4.dart';

part 'error_envelope.g.dart';

@JsonSerializable()
class ErrorEnvelope {
  const ErrorEnvelope({required this.error});

  factory ErrorEnvelope.fromJson(Map<String, Object?> json) =>
      _$ErrorEnvelopeFromJson(json);

  final Error4 error;

  Map<String, Object?> toJson() => _$ErrorEnvelopeToJson(this);
}
