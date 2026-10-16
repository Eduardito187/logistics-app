// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_roles_role_id_request_body.g.dart';

@JsonSerializable()
class AppAccessRolesRoleIdRequestBody {
  const AppAccessRolesRoleIdRequestBody({required this.name, this.description});

  factory AppAccessRolesRoleIdRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAccessRolesRoleIdRequestBodyFromJson(json);

  final String name;
  final String? description;

  Map<String, Object?> toJson() =>
      _$AppAccessRolesRoleIdRequestBodyToJson(this);
}
