// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_notifications_all_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppNotificationsAllResponse _$GetAppNotificationsAllResponseFromJson(
  Map<String, dynamic> json,
) => GetAppNotificationsAllResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => NotificationView.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppNotificationsAllResponseToJson(
  GetAppNotificationsAllResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
