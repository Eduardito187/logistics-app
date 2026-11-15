// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notifications_read_all_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotificationsReadAllRequestBody _$AppNotificationsReadAllRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppNotificationsReadAllRequestBody(
  upTo: json['up_to'] == null ? null : DateTime.parse(json['up_to'] as String),
);

Map<String, dynamic> _$AppNotificationsReadAllRequestBodyToJson(
  AppNotificationsReadAllRequestBody instance,
) => <String, dynamic>{'up_to': instance.upTo?.toIso8601String()};
