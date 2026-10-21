// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data22.dart';

part 'accepted_envelope.g.dart';

@JsonSerializable()
class AcceptedEnvelope {
  const AcceptedEnvelope({required this.data});

  factory AcceptedEnvelope.fromJson(Map<String, Object?> json) =>
      _$AcceptedEnvelopeFromJson(json);

  final Data22 data;

  Map<String, Object?> toJson() => _$AcceptedEnvelopeToJson(this);
}
