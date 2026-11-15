// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_crews_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetCrewsResponse _$GetAppFleetCrewsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetCrewsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => FleetListCrewsItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetCrewsResponseToJson(
  GetAppFleetCrewsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
