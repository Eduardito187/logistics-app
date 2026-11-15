// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_staff_user_id_photo_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppStaffUserIdPhotoResponse _$PostAppStaffUserIdPhotoResponseFromJson(
  Map<String, dynamic> json,
) => PostAppStaffUserIdPhotoResponse(
  data: json['data'] == null
      ? null
      : StaffProfile.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppStaffUserIdPhotoResponseToJson(
  PostAppStaffUserIdPhotoResponse instance,
) => <String, dynamic>{'data': instance.data};
