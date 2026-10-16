// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sms_budget.dart';

part 'get_app_notification_sms_budget_response.g.dart';

@JsonSerializable()
class GetAppNotificationSmsBudgetResponse {
  const GetAppNotificationSmsBudgetResponse({required this.data});

  factory GetAppNotificationSmsBudgetResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppNotificationSmsBudgetResponseFromJson(json);

  final SmsBudget data;

  Map<String, Object?> toJson() =>
      _$GetAppNotificationSmsBudgetResponseToJson(this);
}
