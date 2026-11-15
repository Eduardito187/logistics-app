// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_channels_pricing_prices_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelsPricingPricesResponse _$GetChannelsPricingPricesResponseFromJson(
  Map<String, dynamic> json,
) => GetChannelsPricingPricesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CommercePriceView.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetChannelsPricingPricesResponseToJson(
  GetChannelsPricingPricesResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
