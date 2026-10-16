// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type_rule.dart';

part 'get_app_notification_rules_response.g.dart';

@JsonSerializable()
class GetAppNotificationRulesResponse {
  const GetAppNotificationRulesResponse({required this.data});

  factory GetAppNotificationRulesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppNotificationRulesResponseFromJson(json);

  final List<MessageTypeRule> data;

  Map<String, Object?> toJson() =>
      _$GetAppNotificationRulesResponseToJson(this);
}
