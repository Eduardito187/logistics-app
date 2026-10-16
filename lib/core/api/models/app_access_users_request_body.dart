// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status5.dart';

part 'app_access_users_request_body.g.dart';

@JsonSerializable()
class AppAccessUsersRequestBody {
  const AppAccessUsersRequestBody({
    required this.name,
    required this.email,
    required this.password,
    this.roleKeys,
    this.status,
  });

  factory AppAccessUsersRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAccessUsersRequestBodyFromJson(json);

  final String name;
  final String email;
  final String password;
  @JsonKey(name: 'role_keys')
  final List<String>? roleKeys;
  final Status5? status;

  Map<String, Object?> toJson() => _$AppAccessUsersRequestBodyToJson(this);
}
