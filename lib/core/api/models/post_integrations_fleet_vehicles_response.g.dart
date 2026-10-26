// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_integrations_fleet_vehicles_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostIntegrationsFleetVehiclesResponse
_$PostIntegrationsFleetVehiclesResponseFromJson(Map<String, dynamic> json) =>
    PostIntegrationsFleetVehiclesResponse(
      data: json['data'] == null
          ? null
          : Data18.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostIntegrationsFleetVehiclesResponseToJson(
  PostIntegrationsFleetVehiclesResponse instance,
) => <String, dynamic>{'data': instance.data};
