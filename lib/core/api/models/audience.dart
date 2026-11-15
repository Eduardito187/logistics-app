// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_role_name.dart';

part 'audience.g.dart';

@JsonSerializable()
class Audience {
  const Audience({
    required this.role,
    required this.nodeId,
    required this.userIds,
  });

  factory Audience.fromJson(Map<String, Object?> json) =>
      _$AudienceFromJson(json);

  final StaffRoleName? role;
  @JsonKey(name: 'node_id')
  final String? nodeId;

  /// Lista vacía o null = no aplica (el aviso va por rol o tienda).
  @JsonKey(name: 'user_ids')
  final List<int>? userIds;

  Map<String, Object?> toJson() => _$AudienceToJson(this);
}
