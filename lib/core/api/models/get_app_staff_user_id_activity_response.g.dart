// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_staff_user_id_activity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppStaffUserIdActivityResponse _$GetAppStaffUserIdActivityResponseFromJson(
  Map<String, dynamic> json,
) => GetAppStaffUserIdActivityResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => StaffActivity.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppStaffUserIdActivityResponseToJson(
  GetAppStaffUserIdActivityResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
