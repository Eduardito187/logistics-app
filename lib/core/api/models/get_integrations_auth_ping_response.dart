// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_integrations_auth_ping_response.g.dart';

@JsonSerializable()
class GetIntegrationsAuthPingResponse {
  const GetIntegrationsAuthPingResponse({
    required this.status,
    this.client,
    this.scopes,
  });

  factory GetIntegrationsAuthPingResponse.fromJson(Map<String, Object?> json) =>
      _$GetIntegrationsAuthPingResponseFromJson(json);

  final String status;
  final String? client;
  final List<String>? scopes;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsAuthPingResponseToJson(this);
}
