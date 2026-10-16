// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_permissions_request_body.g.dart';

@JsonSerializable()
class AppAccessPermissionsRequestBody {
  const AppAccessPermissionsRequestBody({
    required this.key,
    this.description,
    this.isSystem,
  });

  factory AppAccessPermissionsRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAccessPermissionsRequestBodyFromJson(json);

  final String key;
  final String? description;
  @JsonKey(name: 'is_system')
  final bool? isSystem;

  Map<String, Object?> toJson() =>
      _$AppAccessPermissionsRequestBodyToJson(this);
}
