// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'issued_token.dart';

part 'post_app_access_tokens_response.g.dart';

@JsonSerializable()
class PostAppAccessTokensResponse {
  const PostAppAccessTokensResponse({required this.data});

  factory PostAppAccessTokensResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppAccessTokensResponseFromJson(json);

  final IssuedToken data;

  Map<String, Object?> toJson() => _$PostAppAccessTokensResponseToJson(this);
}
