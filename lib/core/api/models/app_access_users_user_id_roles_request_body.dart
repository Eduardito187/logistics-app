// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_users_user_id_roles_request_body.g.dart';

@JsonSerializable()
class AppAccessUsersUserIdRolesRequestBody {
  const AppAccessUsersUserIdRolesRequestBody({required this.roleKey});

  factory AppAccessUsersUserIdRolesRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppAccessUsersUserIdRolesRequestBodyFromJson(json);

  @JsonKey(name: 'role_key')
  final String roleKey;

  Map<String, Object?> toJson() =>
      _$AppAccessUsersUserIdRolesRequestBodyToJson(this);
}
