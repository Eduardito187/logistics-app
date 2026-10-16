// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auto_plan_run.dart';

part 'auto_plan_run_envelope.g.dart';

@JsonSerializable()
class AutoPlanRunEnvelope {
  const AutoPlanRunEnvelope({required this.data});

  factory AutoPlanRunEnvelope.fromJson(Map<String, Object?> json) =>
      _$AutoPlanRunEnvelopeFromJson(json);

  final AutoPlanRun data;

  Map<String, Object?> toJson() => _$AutoPlanRunEnvelopeToJson(this);
}
