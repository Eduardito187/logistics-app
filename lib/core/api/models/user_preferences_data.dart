// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_preferences_data.g.dart';

@JsonSerializable()
class UserPreferencesData {
  const UserPreferencesData({
    required this.preferences,
    required this.updatedAt,
    this.ignoredKeys,
  });

  factory UserPreferencesData.fromJson(Map<String, Object?> json) =>
      _$UserPreferencesDataFromJson(json);

  final dynamic preferences;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// PUT only; keys whose change was older than the last accepted change (last-write-wins per key).
  @JsonKey(name: 'ignored_keys')
  final List<String>? ignoredKeys;

  Map<String, Object?> toJson() => _$UserPreferencesDataToJson(this);
}
