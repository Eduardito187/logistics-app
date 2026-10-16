// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_access_tokens_token_id_permissions_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppAccessTokensTokenIdPermissionsRequestBody
_$AppAccessTokensTokenIdPermissionsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppAccessTokensTokenIdPermissionsRequestBody(
  permissionKeys: (json['permission_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AppAccessTokensTokenIdPermissionsRequestBodyToJson(
  AppAccessTokensTokenIdPermissionsRequestBody instance,
) => <String, dynamic>{'permission_keys': instance.permissionKeys};
