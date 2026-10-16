// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_roles_role_id_permissions_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessRolesRoleIdPermissionsRequestBody
_$AppAccessRolesRoleIdPermissionsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessRolesRoleIdPermissionsRequestBody(
  permissionKeys: (json['permission_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AppAccessRolesRoleIdPermissionsRequestBodyToJson(
  AppAccessRolesRoleIdPermissionsRequestBody instance,
) => <String, dynamic>{'permission_keys': instance.permissionKeys};
