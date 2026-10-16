// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_roles_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessRolesRequestBody _$AppAccessRolesRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessRolesRequestBody(
  key: json['key'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  permissionKeys: (json['permission_keys'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isSystem: json['is_system'] as bool?,
);

Map<String, dynamic> _$AppAccessRolesRequestBodyToJson(
  AppAccessRolesRequestBody instance,
) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'description': instance.description,
  'permission_keys': instance.permissionKeys,
  'is_system': instance.isSystem,
};
