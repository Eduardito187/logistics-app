// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_view.dart';

part 'get_app_notifications_notification_response.g.dart';

@JsonSerializable()
class GetAppNotificationsNotificationResponse {
  const GetAppNotificationsNotificationResponse({required this.data});

  factory GetAppNotificationsNotificationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppNotificationsNotificationResponseFromJson(json);

  final NotificationView data;

  Map<String, Object?> toJson() =>
      _$GetAppNotificationsNotificationResponseToJson(this);
}
