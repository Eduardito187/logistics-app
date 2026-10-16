// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_user_profile.g.dart';

@JsonSerializable()
class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory AppUserProfile.fromJson(Map<String, Object?> json) =>
      _$AppUserProfileFromJson(json);

  /// User primary key (auto-increment).
  final int id;
  final String name;
  final String email;
  final List<String> roles;

  Map<String, Object?> toJson() => _$AppUserProfileToJson(this);
}
