// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_mark_notification_read_data.dart';

part 'post_app_notifications_notification_read_response.g.dart';

@JsonSerializable()
class PostAppNotificationsNotificationReadResponse {
  const PostAppNotificationsNotificationReadResponse({required this.data});

  factory PostAppNotificationsNotificationReadResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppNotificationsNotificationReadResponseFromJson(json);

  final AppMarkNotificationReadData data;

  Map<String, Object?> toJson() =>
      _$PostAppNotificationsNotificationReadResponseToJson(this);
}
