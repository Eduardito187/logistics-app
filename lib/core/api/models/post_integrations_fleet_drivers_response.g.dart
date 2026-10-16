// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_integrations_fleet_drivers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostIntegrationsFleetDriversResponse
_$PostIntegrationsFleetDriversResponseFromJson(Map<String, dynamic> json) =>
    PostIntegrationsFleetDriversResponse(
      data: json['data'] == null
          ? null
          : Data15.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostIntegrationsFleetDriversResponseToJson(
  PostIntegrationsFleetDriversResponse instance,
) => <String, dynamic>{'data': instance.data};
