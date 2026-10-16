// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_permissions_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessPermissionsRequestBody _$AppAccessPermissionsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessPermissionsRequestBody(
  key: json['key'] as String,
  description: json['description'] as String?,
  isSystem: json['is_system'] as bool?,
);

Map<String, dynamic> _$AppAccessPermissionsRequestBodyToJson(
  AppAccessPermissionsRequestBody instance,
) => <String, dynamic>{
  'key': instance.key,
  'description': instance.description,
  'is_system': instance.isSystem,
};
