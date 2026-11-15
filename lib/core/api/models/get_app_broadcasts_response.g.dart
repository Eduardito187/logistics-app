// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_broadcasts_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppBroadcastsResponse _$GetAppBroadcastsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppBroadcastsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => StaffBroadcast.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppBroadcastsResponseToJson(
  GetAppBroadcastsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
