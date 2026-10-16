// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user.dart';

part 'get_app_access_users_user_id_response.g.dart';

@JsonSerializable()
class GetAppAccessUsersUserIdResponse {
  const GetAppAccessUsersUserIdResponse({required this.data});

  factory GetAppAccessUsersUserIdResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppAccessUsersUserIdResponseFromJson(json);

  final User data;

  Map<String, Object?> toJson() =>
      _$GetAppAccessUsersUserIdResponseToJson(this);
}
