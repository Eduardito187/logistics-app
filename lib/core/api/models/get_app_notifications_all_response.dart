// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_view.dart';
import 'list_meta.dart';

part 'get_app_notifications_all_response.g.dart';

@JsonSerializable()
class GetAppNotificationsAllResponse {
  const GetAppNotificationsAllResponse({required this.data, this.meta});

  factory GetAppNotificationsAllResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppNotificationsAllResponseFromJson(json);

  final List<NotificationView> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppNotificationsAllResponseToJson(this);
}
