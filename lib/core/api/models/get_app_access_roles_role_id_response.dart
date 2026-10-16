// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';

part 'get_app_access_roles_role_id_response.g.dart';

@JsonSerializable()
class GetAppAccessRolesRoleIdResponse {
  const GetAppAccessRolesRoleIdResponse({required this.data});

  factory GetAppAccessRolesRoleIdResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppAccessRolesRoleIdResponseFromJson(json);

  final Role data;

  Map<String, Object?> toJson() =>
      _$GetAppAccessRolesRoleIdResponseToJson(this);
}
