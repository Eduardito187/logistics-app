// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_users_user_id_password_request_body.g.dart';

@JsonSerializable()
class AppAccessUsersUserIdPasswordRequestBody {
  const AppAccessUsersUserIdPasswordRequestBody({required this.password});

  factory AppAccessUsersUserIdPasswordRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppAccessUsersUserIdPasswordRequestBodyFromJson(json);

  final String password;

  Map<String, Object?> toJson() =>
      _$AppAccessUsersUserIdPasswordRequestBodyToJson(this);
}
