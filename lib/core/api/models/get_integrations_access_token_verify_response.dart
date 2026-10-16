// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'token_verification.dart';

part 'get_integrations_access_token_verify_response.g.dart';

@JsonSerializable()
class GetIntegrationsAccessTokenVerifyResponse {
  const GetIntegrationsAccessTokenVerifyResponse({required this.data});

  factory GetIntegrationsAccessTokenVerifyResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsAccessTokenVerifyResponseFromJson(json);

  final TokenVerification data;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsAccessTokenVerifyResponseToJson(this);
}
