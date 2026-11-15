// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_maintenance_due_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsMaintenanceDueResponse
_$GetAppFleetopsMaintenanceDueResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetopsMaintenanceDueResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => DueMaintenanceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppFleetopsMaintenanceDueResponseToJson(
  GetAppFleetopsMaintenanceDueResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
