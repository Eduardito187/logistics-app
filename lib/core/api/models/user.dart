// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_status.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roleKeys,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);

  final String id;
  final String name;
  final String email;
  final UserStatus status;
  @JsonKey(name: 'role_keys')
  final List<String> roleKeys;
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;

  Map<String, Object?> toJson() => _$UserToJson(this);
}
