// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_maintenance_plans_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsMaintenancePlansResponse
_$GetAppFleetopsMaintenancePlansResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetopsMaintenancePlansResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => MaintenancePlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAppFleetopsMaintenancePlansResponseToJson(
  GetAppFleetopsMaintenancePlansResponse instance,
) => <String, dynamic>{'data': instance.data};
