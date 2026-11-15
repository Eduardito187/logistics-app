// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_inbox_read_all_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppInboxReadAllResponse _$PostAppInboxReadAllResponseFromJson(
  Map<String, dynamic> json,
) => PostAppInboxReadAllResponse(
  data: json['data'] == null
      ? null
      : MarkInboxAllReadData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppInboxReadAllResponseToJson(
  PostAppInboxReadAllResponse instance,
) => <String, dynamic>{'data': instance.data};
