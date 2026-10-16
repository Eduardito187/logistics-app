// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_roles_role_id_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessRolesRoleIdRequestBody _$AppAccessRolesRoleIdRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessRolesRoleIdRequestBody(
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$AppAccessRolesRoleIdRequestBodyToJson(
  AppAccessRolesRoleIdRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
};
