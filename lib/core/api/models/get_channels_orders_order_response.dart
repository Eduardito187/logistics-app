// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_order.dart';

part 'get_channels_orders_order_response.g.dart';

@JsonSerializable()
class GetChannelsOrdersOrderResponse {
  const GetChannelsOrdersOrderResponse({required this.data});

  factory GetChannelsOrdersOrderResponse.fromJson(Map<String, Object?> json) =>
      _$GetChannelsOrdersOrderResponseFromJson(json);

  final CommerceOrder data;

  Map<String, Object?> toJson() => _$GetChannelsOrdersOrderResponseToJson(this);
}
