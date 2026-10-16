// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_integrations_fleet_helpers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostIntegrationsFleetHelpersResponse
_$PostIntegrationsFleetHelpersResponseFromJson(Map<String, dynamic> json) =>
    PostIntegrationsFleetHelpersResponse(
      data: json['data'] == null
          ? null
          : Data16.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostIntegrationsFleetHelpersResponseToJson(
  PostIntegrationsFleetHelpersResponse instance,
) => <String, dynamic>{'data': instance.data};
