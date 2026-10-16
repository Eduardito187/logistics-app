// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_tokens_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessTokensRequestBody _$AppAccessTokensRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessTokensRequestBody(
  name: json['name'] as String,
  permissionKeys: (json['permission_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$AppAccessTokensRequestBodyToJson(
  AppAccessTokensRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'permission_keys': instance.permissionKeys,
  'expires_at': instance.expiresAt?.toIso8601String(),
};
