// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_preferences_data.dart';

part 'user_preferences.g.dart';

@JsonSerializable()
class UserPreferences {
  const UserPreferences({required this.data});

  factory UserPreferences.fromJson(Map<String, Object?> json) =>
      _$UserPreferencesFromJson(json);

  final UserPreferencesData data;

  Map<String, Object?> toJson() => _$UserPreferencesToJson(this);
}
