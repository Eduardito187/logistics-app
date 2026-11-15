// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_price_quote.dart';

part 'get_channels_pricing_price_response.g.dart';

@JsonSerializable()
class GetChannelsPricingPriceResponse {
  const GetChannelsPricingPriceResponse({required this.data});

  factory GetChannelsPricingPriceResponse.fromJson(Map<String, Object?> json) =>
      _$GetChannelsPricingPriceResponseFromJson(json);

  final CommercePriceQuote data;

  Map<String, Object?> toJson() =>
      _$GetChannelsPricingPriceResponseToJson(this);
}
