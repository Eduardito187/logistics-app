// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_inbox_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppInboxResponse _$GetAppInboxResponseFromJson(Map<String, dynamic> json) =>
    GetAppInboxResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => StaffInboxItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppInboxResponseToJson(
  GetAppInboxResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
