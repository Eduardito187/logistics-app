// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_integrations_auth_ping_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIntegrationsAuthPingResponse _$GetIntegrationsAuthPingResponseFromJson(
  Map<String, dynamic> json,
) => GetIntegrationsAuthPingResponse(
  status: json['status'] as String,
  client: json['client'] as String?,
  scopes: (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$GetIntegrationsAuthPingResponseToJson(
  GetIntegrationsAuthPingResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'client': instance.client,
  'scopes': instance.scopes,
};
