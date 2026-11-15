// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_orders_order_initial_paid_response.g.dart';

@JsonSerializable()
class PostIntegrationsOrdersOrderInitialPaidResponse {
  const PostIntegrationsOrdersOrderInitialPaidResponse({required this.data});

  factory PostIntegrationsOrdersOrderInitialPaidResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsOrdersOrderInitialPaidResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsOrdersOrderInitialPaidResponseToJson(this);
}
