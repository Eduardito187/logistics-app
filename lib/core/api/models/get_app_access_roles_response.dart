// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';

part 'get_app_access_roles_response.g.dart';

@JsonSerializable()
class GetAppAccessRolesResponse {
  const GetAppAccessRolesResponse({required this.data});

  factory GetAppAccessRolesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppAccessRolesResponseFromJson(json);

  final List<Role> data;

  Map<String, Object?> toJson() => _$GetAppAccessRolesResponseToJson(this);
}
