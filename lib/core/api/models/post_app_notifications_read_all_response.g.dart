// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_notifications_read_all_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppNotificationsReadAllResponse
_$PostAppNotificationsReadAllResponseFromJson(Map<String, dynamic> json) =>
    PostAppNotificationsReadAllResponse(
      data: AppMarkAllNotificationsReadData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PostAppNotificationsReadAllResponseToJson(
  PostAppNotificationsReadAllResponse instance,
) => <String, dynamic>{'data': instance.data};
