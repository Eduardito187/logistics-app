// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_roles_request_body.g.dart';

@JsonSerializable()
class AppAccessRolesRequestBody {
  const AppAccessRolesRequestBody({
    required this.key,
    required this.name,
    this.description,
    this.permissionKeys,
    this.isSystem,
  });

  factory AppAccessRolesRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAccessRolesRequestBodyFromJson(json);

  final String key;
  final String name;
  final String? description;
  @JsonKey(name: 'permission_keys')
  final List<String>? permissionKeys;
  @JsonKey(name: 'is_system')
  final bool? isSystem;

  Map<String, Object?> toJson() => _$AppAccessRolesRequestBodyToJson(this);
}
