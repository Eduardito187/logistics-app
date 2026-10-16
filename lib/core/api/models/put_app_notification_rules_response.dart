// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type_rule.dart';

part 'put_app_notification_rules_response.g.dart';

@JsonSerializable()
class PutAppNotificationRulesResponse {
  const PutAppNotificationRulesResponse({required this.data});

  factory PutAppNotificationRulesResponse.fromJson(Map<String, Object?> json) =>
      _$PutAppNotificationRulesResponseFromJson(json);

  final MessageTypeRule data;

  Map<String, Object?> toJson() =>
      _$PutAppNotificationRulesResponseToJson(this);
}
