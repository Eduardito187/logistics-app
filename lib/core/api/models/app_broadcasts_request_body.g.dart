// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_broadcasts_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBroadcastsRequestBody _$AppBroadcastsRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppBroadcastsRequestBody(
  audience: Audience.fromJson(json['audience'] as Map<String, dynamic>),
  title: json['title'] as String,
  body: json['body'] as String,
  link: json['link'] as String?,
);

Map<String, dynamic> _$AppBroadcastsRequestBodyToJson(
  AppBroadcastsRequestBody instance,
) => <String, dynamic>{
  'audience': instance.audience,
  'title': instance.title,
  'body': instance.body,
  'link': instance.link,
};
