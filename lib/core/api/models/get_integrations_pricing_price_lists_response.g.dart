// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_integrations_pricing_price_lists_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIntegrationsPricingPriceListsResponse
_$GetIntegrationsPricingPriceListsResponseFromJson(Map<String, dynamic> json) =>
    GetIntegrationsPricingPriceListsResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CommercePriceList.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetIntegrationsPricingPriceListsResponseToJson(
  GetIntegrationsPricingPriceListsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
