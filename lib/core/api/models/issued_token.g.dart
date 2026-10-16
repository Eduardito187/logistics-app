// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issued_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssuedToken _$IssuedTokenFromJson(Map<String, dynamic> json) => IssuedToken(
  id: json['id'] as String,
  name: json['name'] as String,
  tokenPrefix: json['token_prefix'] as String,
  plainToken: json['plain_token'] as String,
  permissionKeys: (json['permission_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$IssuedTokenToJson(IssuedToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'token_prefix': instance.tokenPrefix,
      'plain_token': instance.plainToken,
      'permission_keys': instance.permissionKeys,
      'expires_at': instance.expiresAt?.toIso8601String(),
    };
