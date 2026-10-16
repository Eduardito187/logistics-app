// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'setting_version.g.dart';

@JsonSerializable()
class SettingVersion {
  const SettingVersion({
    required this.id,
    required this.key,
    required this.version,
    required this.value,
    required this.effectiveFrom,
    required this.createdAt,
    required this.createdBy,
  });

  factory SettingVersion.fromJson(Map<String, Object?> json) =>
      _$SettingVersionFromJson(json);

  final String id;
  final String key;
  final int version;
  final dynamic value;
  @JsonKey(name: 'effective_from')
  final DateTime effectiveFrom;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'created_by')
  final String? createdBy;

  Map<String, Object?> toJson() => _$SettingVersionToJson(this);
}
