// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_auth_password_reset_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAuthPasswordResetRequestBody _$AppAuthPasswordResetRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAuthPasswordResetRequestBody(
  email: json['email'] as String,
  code: json['code'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$AppAuthPasswordResetRequestBodyToJson(
  AppAuthPasswordResetRequestBody instance,
) => <String, dynamic>{
  'email': instance.email,
  'code': instance.code,
  'password': instance.password,
};
