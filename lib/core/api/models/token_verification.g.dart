// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenVerification _$TokenVerificationFromJson(Map<String, dynamic> json) =>
    TokenVerification(
      tokenId: json['token_id'] as String,
      permissionKeys: (json['permission_keys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TokenVerificationToJson(TokenVerification instance) =>
    <String, dynamic>{
      'token_id': instance.tokenId,
      'permission_keys': instance.permissionKeys,
    };
