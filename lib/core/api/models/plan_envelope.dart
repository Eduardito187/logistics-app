// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan.dart';

part 'plan_envelope.g.dart';

@JsonSerializable()
class PlanEnvelope {
  const PlanEnvelope({required this.data});

  factory PlanEnvelope.fromJson(Map<String, Object?> json) =>
      _$PlanEnvelopeFromJson(json);

  final Plan data;

  Map<String, Object?> toJson() => _$PlanEnvelopeToJson(this);
}
