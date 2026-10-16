// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_roles_role_id_permissions_request_body.g.dart';

@JsonSerializable()
class AppAccessRolesRoleIdPermissionsRequestBody {
  const AppAccessRolesRoleIdPermissionsRequestBody({
    required this.permissionKeys,
  });

  factory AppAccessRolesRoleIdPermissionsRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppAccessRolesRoleIdPermissionsRequestBodyFromJson(json);

  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;

  Map<String, Object?> toJson() =>
      _$AppAccessRolesRoleIdPermissionsRequestBodyToJson(this);
}
