// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_vehicle_profiles_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsVehicleProfilesResponse
_$GetAppFleetopsVehicleProfilesResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetopsVehicleProfilesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => VehicleProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAppFleetopsVehicleProfilesResponseToJson(
  GetAppFleetopsVehicleProfilesResponse instance,
) => <String, dynamic>{'data': instance.data};
