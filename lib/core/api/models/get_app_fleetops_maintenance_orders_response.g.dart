// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_maintenance_orders_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsMaintenanceOrdersResponse
_$GetAppFleetopsMaintenanceOrdersResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetopsMaintenanceOrdersResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => MaintenanceOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAppFleetopsMaintenanceOrdersResponseToJson(
  GetAppFleetopsMaintenanceOrdersResponse instance,
) => <String, dynamic>{'data': instance.data};
