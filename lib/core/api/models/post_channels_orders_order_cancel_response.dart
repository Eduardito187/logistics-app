// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_channels_orders_order_cancel_response.g.dart';

@JsonSerializable()
class PostChannelsOrdersOrderCancelResponse {
  const PostChannelsOrdersOrderCancelResponse({required this.data});

  factory PostChannelsOrdersOrderCancelResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsOrdersOrderCancelResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostChannelsOrdersOrderCancelResponseToJson(this);
}
