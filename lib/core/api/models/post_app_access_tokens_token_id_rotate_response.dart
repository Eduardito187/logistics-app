// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'issued_token.dart';

part 'post_app_access_tokens_token_id_rotate_response.g.dart';

@JsonSerializable()
class PostAppAccessTokensTokenIdRotateResponse {
  const PostAppAccessTokensTokenIdRotateResponse({required this.data});

  factory PostAppAccessTokensTokenIdRotateResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppAccessTokensTokenIdRotateResponseFromJson(json);

  final IssuedToken data;

  Map<String, Object?> toJson() =>
      _$PostAppAccessTokensTokenIdRotateResponseToJson(this);
}
