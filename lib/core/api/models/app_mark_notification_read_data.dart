// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_mark_notification_read_data.g.dart';

@JsonSerializable()
class AppMarkNotificationReadData {
  const AppMarkNotificationReadData({
    required this.notificationId,
    required this.readAt,
    required this.unreadCount,
  });

  factory AppMarkNotificationReadData.fromJson(Map<String, Object?> json) =>
      _$AppMarkNotificationReadDataFromJson(json);

  @JsonKey(name: 'notification_id')
  final String notificationId;
  @JsonKey(name: 'read_at')
  final DateTime readAt;
  @JsonKey(name: 'unread_count')
  final int unreadCount;

  Map<String, Object?> toJson() => _$AppMarkNotificationReadDataToJson(this);
}
