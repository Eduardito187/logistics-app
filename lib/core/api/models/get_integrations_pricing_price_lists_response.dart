// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_price_list.dart';
import 'list_meta.dart';

part 'get_integrations_pricing_price_lists_response.g.dart';

@JsonSerializable()
class GetIntegrationsPricingPriceListsResponse {
  const GetIntegrationsPricingPriceListsResponse({
    required this.data,
    this.meta,
  });

  factory GetIntegrationsPricingPriceListsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsPricingPriceListsResponseFromJson(json);

  final List<CommercePriceList> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsPricingPriceListsResponseToJson(this);
}
