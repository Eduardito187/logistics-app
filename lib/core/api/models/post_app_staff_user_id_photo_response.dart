// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_profile.dart';

part 'post_app_staff_user_id_photo_response.g.dart';

@JsonSerializable()
class PostAppStaffUserIdPhotoResponse {
  const PostAppStaffUserIdPhotoResponse({this.data});

  factory PostAppStaffUserIdPhotoResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppStaffUserIdPhotoResponseFromJson(json);

  final StaffProfile? data;

  Map<String, Object?> toJson() =>
      _$PostAppStaffUserIdPhotoResponseToJson(this);
}
