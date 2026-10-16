// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationToken _$IntegrationTokenFromJson(Map<String, dynamic> json) =>
    IntegrationToken(
      id: json['id'] as String,
      name: json['name'] as String,
      tokenPrefix: json['token_prefix'] as String,
      status: IntegrationTokenStatus.fromJson(json['status'] as String),
      permissionKeys: (json['permission_keys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$IntegrationTokenToJson(IntegrationToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'token_prefix': instance.tokenPrefix,
      'status': instance.status,
      'permission_keys': instance.permissionKeys,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
