// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user.dart';
import 'list_meta.dart';

part 'get_app_access_users_response.g.dart';

@JsonSerializable()
class GetAppAccessUsersResponse {
  const GetAppAccessUsersResponse({required this.data, this.meta});

  factory GetAppAccessUsersResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppAccessUsersResponseFromJson(json);

  final List<User> data;

  /// Present only when pagination parameters are sent.
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppAccessUsersResponseToJson(this);
}
