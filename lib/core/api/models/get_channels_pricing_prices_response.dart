// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_price_view.dart';
import 'list_meta.dart';

part 'get_channels_pricing_prices_response.g.dart';

@JsonSerializable()
class GetChannelsPricingPricesResponse {
  const GetChannelsPricingPricesResponse({required this.data, this.meta});

  factory GetChannelsPricingPricesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsPricingPricesResponseFromJson(json);

  final List<CommercePriceView> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetChannelsPricingPricesResponseToJson(this);
}
