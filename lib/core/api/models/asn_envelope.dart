// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'asn.dart';

part 'asn_envelope.g.dart';

@JsonSerializable()
class AsnEnvelope {
  const AsnEnvelope({required this.data});

  factory AsnEnvelope.fromJson(Map<String, Object?> json) =>
      _$AsnEnvelopeFromJson(json);

  final Asn data;

  Map<String, Object?> toJson() => _$AsnEnvelopeToJson(this);
}
