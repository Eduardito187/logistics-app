// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_staff_user_id_photos_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppStaffUserIdPhotosResponse _$GetAppStaffUserIdPhotosResponseFromJson(
  Map<String, dynamic> json,
) => GetAppStaffUserIdPhotosResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => StaffPhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppStaffUserIdPhotosResponseToJson(
  GetAppStaffUserIdPhotosResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
