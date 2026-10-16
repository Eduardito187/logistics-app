// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'integration_token.dart';

part 'get_app_access_tokens_token_id_response.g.dart';

@JsonSerializable()
class GetAppAccessTokensTokenIdResponse {
  const GetAppAccessTokensTokenIdResponse({required this.data});

  factory GetAppAccessTokensTokenIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppAccessTokensTokenIdResponseFromJson(json);

  final IntegrationToken data;

  Map<String, Object?> toJson() =>
      _$GetAppAccessTokensTokenIdResponseToJson(this);
}
