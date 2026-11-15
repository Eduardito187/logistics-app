// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_broadcasts_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppBroadcastsResponse _$PostAppBroadcastsResponseFromJson(
  Map<String, dynamic> json,
) => PostAppBroadcastsResponse(
  data: json['data'] == null
      ? null
      : SendStaffBroadcastData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppBroadcastsResponseToJson(
  PostAppBroadcastsResponse instance,
) => <String, dynamic>{'data': instance.data};
