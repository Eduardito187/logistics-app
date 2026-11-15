// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_activity.dart';
import 'list_meta.dart';

part 'get_app_staff_user_id_activity_response.g.dart';

@JsonSerializable()
class GetAppStaffUserIdActivityResponse {
  const GetAppStaffUserIdActivityResponse({
    required this.data,
    required this.meta,
  });

  factory GetAppStaffUserIdActivityResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppStaffUserIdActivityResponseFromJson(json);

  final List<StaffActivity> data;
  final ListMeta meta;

  Map<String, Object?> toJson() =>
      _$GetAppStaffUserIdActivityResponseToJson(this);
}
