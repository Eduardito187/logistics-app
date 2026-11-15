// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_auth2fa_disable_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAuth2faDisableRequestBody _$AppAuth2faDisableRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAuth2faDisableRequestBody(
  code: json['code'] as String?,
  password: json['password'] as String?,
);

Map<String, dynamic> _$AppAuth2faDisableRequestBodyToJson(
  AppAuth2faDisableRequestBody instance,
) => <String, dynamic>{'code': instance.code, 'password': instance.password};
