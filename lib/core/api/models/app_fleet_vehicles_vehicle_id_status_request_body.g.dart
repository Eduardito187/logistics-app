// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_fleet_vehicles_vehicle_id_status_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppFleetVehiclesVehicleIdStatusRequestBody
_$AppFleetVehiclesVehicleIdStatusRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppFleetVehiclesVehicleIdStatusRequestBody(
  status: VehicleStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$AppFleetVehiclesVehicleIdStatusRequestBodyToJson(
  AppFleetVehiclesVehicleIdStatusRequestBody instance,
) => <String, dynamic>{'status': instance.status};
