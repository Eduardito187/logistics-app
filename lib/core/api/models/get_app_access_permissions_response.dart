// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'permission.dart';

part 'get_app_access_permissions_response.g.dart';

@JsonSerializable()
class GetAppAccessPermissionsResponse {
  const GetAppAccessPermissionsResponse({required this.data});

  factory GetAppAccessPermissionsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppAccessPermissionsResponseFromJson(json);

  final List<Permission> data;

  Map<String, Object?> toJson() =>
      _$GetAppAccessPermissionsResponseToJson(this);
}
