// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_vehicles_vehicle_id_deliveries_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppVehiclesVehicleIdDeliveriesResponse
_$GetAppVehiclesVehicleIdDeliveriesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppVehiclesVehicleIdDeliveriesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Delivery.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta5.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppVehiclesVehicleIdDeliveriesResponseToJson(
  GetAppVehiclesVehicleIdDeliveriesResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
