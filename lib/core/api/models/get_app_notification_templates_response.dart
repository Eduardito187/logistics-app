// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_template.dart';

part 'get_app_notification_templates_response.g.dart';

@JsonSerializable()
class GetAppNotificationTemplatesResponse {
  const GetAppNotificationTemplatesResponse({required this.data});

  factory GetAppNotificationTemplatesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppNotificationTemplatesResponseFromJson(json);

  final List<MessageTemplate> data;

  Map<String, Object?> toJson() =>
      _$GetAppNotificationTemplatesResponseToJson(this);
}
