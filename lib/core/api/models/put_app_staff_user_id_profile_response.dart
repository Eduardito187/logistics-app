// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_profile.dart';

part 'put_app_staff_user_id_profile_response.g.dart';

@JsonSerializable()
class PutAppStaffUserIdProfileResponse {
  const PutAppStaffUserIdProfileResponse({this.data});

  factory PutAppStaffUserIdProfileResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PutAppStaffUserIdProfileResponseFromJson(json);

  final StaffProfile? data;

  Map<String, Object?> toJson() =>
      _$PutAppStaffUserIdProfileResponseToJson(this);
}
