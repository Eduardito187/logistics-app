// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_mark_all_notifications_read_data.dart';

part 'post_app_notifications_read_all_response.g.dart';

@JsonSerializable()
class PostAppNotificationsReadAllResponse {
  const PostAppNotificationsReadAllResponse({required this.data});

  factory PostAppNotificationsReadAllResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppNotificationsReadAllResponseFromJson(json);

  final AppMarkAllNotificationsReadData data;

  Map<String, Object?> toJson() =>
      _$PostAppNotificationsReadAllResponseToJson(this);
}
