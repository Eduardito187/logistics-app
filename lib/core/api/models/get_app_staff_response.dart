// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_member.dart';
import 'list_meta.dart';

part 'get_app_staff_response.g.dart';

@JsonSerializable()
class GetAppStaffResponse {
  const GetAppStaffResponse({required this.data, required this.meta});

  factory GetAppStaffResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppStaffResponseFromJson(json);

  final List<StaffMember> data;
  final ListMeta meta;

  Map<String, Object?> toJson() => _$GetAppStaffResponseToJson(this);
}
