// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'setting_envelope_data.g.dart';

@JsonSerializable()
class SettingEnvelopeData {
  const SettingEnvelopeData({required this.key, required this.value});

  factory SettingEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$SettingEnvelopeDataFromJson(json);

  final String key;
  final dynamic value;

  Map<String, Object?> toJson() => _$SettingEnvelopeDataToJson(this);
}
