// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_mark_notification_read_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMarkNotificationReadData _$AppMarkNotificationReadDataFromJson(
  Map<String, dynamic> json,
) => AppMarkNotificationReadData(
  notificationId: json['notification_id'] as String,
  readAt: DateTime.parse(json['read_at'] as String),
  unreadCount: (json['unread_count'] as num).toInt(),
);

Map<String, dynamic> _$AppMarkNotificationReadDataToJson(
  AppMarkNotificationReadData instance,
) => <String, dynamic>{
  'notification_id': instance.notificationId,
  'read_at': instance.readAt.toIso8601String(),
  'unread_count': instance.unreadCount,
};
