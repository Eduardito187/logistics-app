// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data27.dart';

part 'setting_envelope.g.dart';

@JsonSerializable()
class SettingEnvelope {
  const SettingEnvelope({required this.data});

  factory SettingEnvelope.fromJson(Map<String, Object?> json) =>
      _$SettingEnvelopeFromJson(json);

  final Data27 data;

  Map<String, Object?> toJson() => _$SettingEnvelopeToJson(this);
}
