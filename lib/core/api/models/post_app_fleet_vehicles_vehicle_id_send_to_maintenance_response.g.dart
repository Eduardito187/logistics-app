// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_fleet_vehicles_vehicle_id_send_to_maintenance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse
_$PostAppFleetVehiclesVehicleIdSendToMaintenanceResponseFromJson(
  Map<String, dynamic> json,
) => PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse(
  data: json['data'] == null
      ? null
      : FleetSendVehicleToMaintenanceData.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic>
_$PostAppFleetVehiclesVehicleIdSendToMaintenanceResponseToJson(
  PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse instance,
) => <String, dynamic>{'data': instance.data};
