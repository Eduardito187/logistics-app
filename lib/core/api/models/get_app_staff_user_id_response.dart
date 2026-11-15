// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_profile.dart';

part 'get_app_staff_user_id_response.g.dart';

@JsonSerializable()
class GetAppStaffUserIdResponse {
  const GetAppStaffUserIdResponse({required this.data});

  factory GetAppStaffUserIdResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppStaffUserIdResponseFromJson(json);

  final StaffProfile data;

  Map<String, Object?> toJson() => _$GetAppStaffUserIdResponseToJson(this);
}
