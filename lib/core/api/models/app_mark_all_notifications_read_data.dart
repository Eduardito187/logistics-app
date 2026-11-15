// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_mark_all_notifications_read_data.g.dart';

@JsonSerializable()
class AppMarkAllNotificationsReadData {
  const AppMarkAllNotificationsReadData({required this.unreadCount});

  factory AppMarkAllNotificationsReadData.fromJson(Map<String, Object?> json) =>
      _$AppMarkAllNotificationsReadDataFromJson(json);

  @JsonKey(name: 'unread_count')
  final int unreadCount;

  Map<String, Object?> toJson() =>
      _$AppMarkAllNotificationsReadDataToJson(this);
}
