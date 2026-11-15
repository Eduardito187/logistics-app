// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_notifications_notification_read_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppNotificationsNotificationReadResponse
_$PostAppNotificationsNotificationReadResponseFromJson(
  Map<String, dynamic> json,
) => PostAppNotificationsNotificationReadResponse(
  data: AppMarkNotificationReadData.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PostAppNotificationsNotificationReadResponseToJson(
  PostAppNotificationsNotificationReadResponse instance,
) => <String, dynamic>{'data': instance.data};
