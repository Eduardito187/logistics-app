// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'effective_capacity.dart';

part 'effective_capacity_envelope.g.dart';

@JsonSerializable()
class EffectiveCapacityEnvelope {
  const EffectiveCapacityEnvelope({required this.data});

  factory EffectiveCapacityEnvelope.fromJson(Map<String, Object?> json) =>
      _$EffectiveCapacityEnvelopeFromJson(json);

  final EffectiveCapacity data;

  Map<String, Object?> toJson() => _$EffectiveCapacityEnvelopeToJson(this);
}
