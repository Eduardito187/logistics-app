// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_lifecycle.dart';

part 'post_app_vehicles_vehicle_id_route_start_response.g.dart';

@JsonSerializable()
class PostAppVehiclesVehicleIdRouteStartResponse {
  const PostAppVehiclesVehicleIdRouteStartResponse({required this.data});

  factory PostAppVehiclesVehicleIdRouteStartResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppVehiclesVehicleIdRouteStartResponseFromJson(json);

  final DriverRouteLifecycle data;

  Map<String, Object?> toJson() =>
      _$PostAppVehiclesVehicleIdRouteStartResponseToJson(this);
}
