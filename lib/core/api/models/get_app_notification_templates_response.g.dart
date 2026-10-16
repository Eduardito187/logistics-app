// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_notification_templates_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppNotificationTemplatesResponse
_$GetAppNotificationTemplatesResponseFromJson(Map<String, dynamic> json) =>
    GetAppNotificationTemplatesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => MessageTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAppNotificationTemplatesResponseToJson(
  GetAppNotificationTemplatesResponse instance,
) => <String, dynamic>{'data': instance.data};
