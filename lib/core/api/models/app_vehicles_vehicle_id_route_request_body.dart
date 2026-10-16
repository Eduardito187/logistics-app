// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stops.dart';

part 'app_vehicles_vehicle_id_route_request_body.g.dart';

@JsonSerializable()
class AppVehiclesVehicleIdRouteRequestBody {
  const AppVehiclesVehicleIdRouteRequestBody({
    required this.routeDate,
    required this.stops,
  });

  factory AppVehiclesVehicleIdRouteRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppVehiclesVehicleIdRouteRequestBodyFromJson(json);

  @JsonKey(name: 'route_date')
  final DateTime routeDate;
  final List<Stops> stops;

  Map<String, Object?> toJson() =>
      _$AppVehiclesVehicleIdRouteRequestBodyToJson(this);
}
