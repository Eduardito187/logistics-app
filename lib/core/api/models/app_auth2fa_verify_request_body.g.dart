// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_auth2fa_verify_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAuth2faVerifyRequestBody _$AppAuth2faVerifyRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAuth2faVerifyRequestBody(
  challengeId: json['challenge_id'] as String,
  code: json['code'] as String,
  email: json['email'] as String?,
);

Map<String, dynamic> _$AppAuth2faVerifyRequestBodyToJson(
  AppAuth2faVerifyRequestBody instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'code': instance.code,
  'email': instance.email,
};
