// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_roles_role_id_permissions_revoke_request_body.g.dart';

@JsonSerializable()
class AppAccessRolesRoleIdPermissionsRevokeRequestBody {
  const AppAccessRolesRoleIdPermissionsRevokeRequestBody({
    required this.permissionKey,
  });

  factory AppAccessRolesRoleIdPermissionsRevokeRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppAccessRolesRoleIdPermissionsRevokeRequestBodyFromJson(json);

  @JsonKey(name: 'permission_key')
  final String permissionKey;

  Map<String, Object?> toJson() =>
      _$AppAccessRolesRoleIdPermissionsRevokeRequestBodyToJson(this);
}
