// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route.dart';

part 'post_app_vehicles_vehicle_id_route_response.g.dart';

@JsonSerializable()
class PostAppVehiclesVehicleIdRouteResponse {
  const PostAppVehiclesVehicleIdRouteResponse({required this.data});

  factory PostAppVehiclesVehicleIdRouteResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppVehiclesVehicleIdRouteResponseFromJson(json);

  final DriverRoute data;

  Map<String, Object?> toJson() =>
      _$PostAppVehiclesVehicleIdRouteResponseToJson(this);
}
