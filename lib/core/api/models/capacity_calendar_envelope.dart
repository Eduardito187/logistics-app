// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_bucket.dart';
import 'meta10.dart';

part 'capacity_calendar_envelope.g.dart';

@JsonSerializable()
class CapacityCalendarEnvelope {
  const CapacityCalendarEnvelope({required this.data, this.meta});

  factory CapacityCalendarEnvelope.fromJson(Map<String, Object?> json) =>
      _$CapacityCalendarEnvelopeFromJson(json);

  final List<CapacityBucket> data;
  final Meta10? meta;

  Map<String, Object?> toJson() => _$CapacityCalendarEnvelopeToJson(this);
}
