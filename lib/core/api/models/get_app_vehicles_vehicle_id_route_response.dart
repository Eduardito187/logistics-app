// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route.dart';

part 'get_app_vehicles_vehicle_id_route_response.g.dart';

@JsonSerializable()
class GetAppVehiclesVehicleIdRouteResponse {
  const GetAppVehiclesVehicleIdRouteResponse({required this.data});

  factory GetAppVehiclesVehicleIdRouteResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppVehiclesVehicleIdRouteResponseFromJson(json);

  final DriverRoute data;

  Map<String, Object?> toJson() =>
      _$GetAppVehiclesVehicleIdRouteResponseToJson(this);
}
