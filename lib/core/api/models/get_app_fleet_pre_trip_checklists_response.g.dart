// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_pre_trip_checklists_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetPreTripChecklistsResponse
_$GetAppFleetPreTripChecklistsResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetPreTripChecklistsResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PreTripChecklist.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppFleetPreTripChecklistsResponseToJson(
  GetAppFleetPreTripChecklistsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
