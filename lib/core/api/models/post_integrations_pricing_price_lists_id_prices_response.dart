// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_pricing_price_lists_id_prices_response.g.dart';

@JsonSerializable()
class PostIntegrationsPricingPriceListsIdPricesResponse {
  const PostIntegrationsPricingPriceListsIdPricesResponse({required this.data});

  factory PostIntegrationsPricingPriceListsIdPricesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsPricingPriceListsIdPricesResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsPricingPriceListsIdPricesResponseToJson(this);
}
