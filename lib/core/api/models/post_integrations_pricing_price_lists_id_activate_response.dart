// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_pricing_price_lists_id_activate_response.g.dart';

@JsonSerializable()
class PostIntegrationsPricingPriceListsIdActivateResponse {
  const PostIntegrationsPricingPriceListsIdActivateResponse({
    required this.data,
  });

  factory PostIntegrationsPricingPriceListsIdActivateResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsPricingPriceListsIdActivateResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsPricingPriceListsIdActivateResponseToJson(this);
}
