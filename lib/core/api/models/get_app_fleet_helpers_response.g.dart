// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_helpers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetHelpersResponse _$GetAppFleetHelpersResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetHelpersResponse(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => Helper.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetHelpersResponseToJson(
  GetAppFleetHelpersResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
