// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'available_to_promise.dart';

part 'available_to_promise_envelope.g.dart';

@JsonSerializable()
class AvailableToPromiseEnvelope {
  const AvailableToPromiseEnvelope({required this.data});

  factory AvailableToPromiseEnvelope.fromJson(Map<String, Object?> json) =>
      _$AvailableToPromiseEnvelopeFromJson(json);

  final AvailableToPromise data;

  Map<String, Object?> toJson() => _$AvailableToPromiseEnvelopeToJson(this);
}
