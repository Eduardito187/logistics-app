// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_notification_rules_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppNotificationRulesResponse _$GetAppNotificationRulesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppNotificationRulesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => MessageTypeRule.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppNotificationRulesResponseToJson(
  GetAppNotificationRulesResponse instance,
) => <String, dynamic>{'data': instance.data};
