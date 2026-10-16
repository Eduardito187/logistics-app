// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_drivers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetDriversResponse _$GetAppFleetDriversResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetDriversResponse(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => Driver.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetDriversResponseToJson(
  GetAppFleetDriversResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
