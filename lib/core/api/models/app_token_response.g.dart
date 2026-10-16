// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppTokenResponse _$AppTokenResponseFromJson(Map<String, dynamic> json) =>
    AppTokenResponse(
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$AppTokenResponseToJson(AppTokenResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'token_type': instance.tokenType,
      'expires_at': instance.expiresAt?.toIso8601String(),
    };
