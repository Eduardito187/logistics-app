// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_users_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessUsersRequestBody _$AppAccessUsersRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessUsersRequestBody(
  name: json['name'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  roleKeys: (json['role_keys'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  status: json['status'] == null
      ? null
      : Status6.fromJson(json['status'] as String),
);

Map<String, dynamic> _$AppAccessUsersRequestBodyToJson(
  AppAccessUsersRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'password': instance.password,
  'role_keys': instance.roleKeys,
  'status': instance.status,
};
