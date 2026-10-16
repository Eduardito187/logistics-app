// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'permission.g.dart';

@JsonSerializable()
class Permission {
  const Permission({
    required this.id,
    required this.key,
    required this.group,
    required this.action,
    required this.isSystem,
    this.description,
  });

  factory Permission.fromJson(Map<String, Object?> json) =>
      _$PermissionFromJson(json);

  final String id;

  /// Clave canónica "grupo.accion" (p. ej. shipments.read). El comodín "*" solo lo siembra el sistema.
  final String key;
  final String group;
  final String action;
  final String? description;
  @JsonKey(name: 'is_system')
  final bool isSystem;

  Map<String, Object?> toJson() => _$PermissionToJson(this);
}
