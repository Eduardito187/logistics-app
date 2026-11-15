// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_orders_order_contract_signed_response.g.dart';

@JsonSerializable()
class PostIntegrationsOrdersOrderContractSignedResponse {
  const PostIntegrationsOrdersOrderContractSignedResponse({required this.data});

  factory PostIntegrationsOrdersOrderContractSignedResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsOrdersOrderContractSignedResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsOrdersOrderContractSignedResponseToJson(this);
}
