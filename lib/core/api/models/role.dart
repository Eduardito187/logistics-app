// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  const Role({
    required this.id,
    required this.key,
    required this.name,
    required this.isSystem,
    required this.permissionKeys,
    this.description,
  });

  factory Role.fromJson(Map<String, Object?> json) => _$RoleFromJson(json);

  final String id;
  final String key;
  final String name;
  final String? description;
  @JsonKey(name: 'is_system')
  final bool isSystem;
  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;

  Map<String, Object?> toJson() => _$RoleToJson(this);
}
