// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_vehicles_vehicle_id_route_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVehiclesVehicleIdRouteRequestBody
_$AppVehiclesVehicleIdRouteRequestBodyFromJson(Map<String, dynamic> json) =>
    AppVehiclesVehicleIdRouteRequestBody(
      routeDate: DateTime.parse(json['route_date'] as String),
      stops: (json['stops'] as List<dynamic>)
          .map((e) => Stops.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppVehiclesVehicleIdRouteRequestBodyToJson(
  AppVehiclesVehicleIdRouteRequestBody instance,
) => <String, dynamic>{
  'route_date': instance.routeDate.toIso8601String(),
  'stops': instance.stops,
};
