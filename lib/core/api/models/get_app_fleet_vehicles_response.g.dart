// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_vehicles_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetVehiclesResponse _$GetAppFleetVehiclesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetVehiclesResponse(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetVehiclesResponseToJson(
  GetAppFleetVehiclesResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
