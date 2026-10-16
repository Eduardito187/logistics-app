// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLoginResponse _$AppLoginResponseFromJson(Map<String, dynamic> json) =>
    AppLoginResponse(
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      user: AppUserProfile.fromJson(json['user'] as Map<String, dynamic>),
      device: AppDevicePayload.fromJson(json['device'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppLoginResponseToJson(AppLoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'token_type': instance.tokenType,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'user': instance.user,
      'device': instance.device,
    };
