// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_photo.dart';
import 'list_meta.dart';

part 'get_app_staff_user_id_photos_response.g.dart';

@JsonSerializable()
class GetAppStaffUserIdPhotosResponse {
  const GetAppStaffUserIdPhotosResponse({
    required this.data,
    required this.meta,
  });

  factory GetAppStaffUserIdPhotosResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppStaffUserIdPhotosResponseFromJson(json);

  final List<StaffPhoto> data;
  final ListMeta meta;

  Map<String, Object?> toJson() =>
      _$GetAppStaffUserIdPhotosResponseToJson(this);
}
