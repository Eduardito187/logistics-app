// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta16.dart';
import 'setting_version.dart';

part 'setting_history_envelope.g.dart';

@JsonSerializable()
class SettingHistoryEnvelope {
  const SettingHistoryEnvelope({required this.data, this.meta});

  factory SettingHistoryEnvelope.fromJson(Map<String, Object?> json) =>
      _$SettingHistoryEnvelopeFromJson(json);

  final List<SettingVersion> data;
  final Meta16? meta;

  Map<String, Object?> toJson() => _$SettingHistoryEnvelopeToJson(this);
}
