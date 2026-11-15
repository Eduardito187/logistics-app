// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_app_staff_user_id_profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutAppStaffUserIdProfileResponse _$PutAppStaffUserIdProfileResponseFromJson(
  Map<String, dynamic> json,
) => PutAppStaffUserIdProfileResponse(
  data: json['data'] == null
      ? null
      : StaffProfile.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PutAppStaffUserIdProfileResponseToJson(
  PutAppStaffUserIdProfileResponse instance,
) => <String, dynamic>{'data': instance.data};
