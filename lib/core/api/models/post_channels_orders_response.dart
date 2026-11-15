// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_checkout_accepted.dart';

part 'post_channels_orders_response.g.dart';

@JsonSerializable()
class PostChannelsOrdersResponse {
  const PostChannelsOrdersResponse({required this.data});

  factory PostChannelsOrdersResponse.fromJson(Map<String, Object?> json) =>
      _$PostChannelsOrdersResponseFromJson(json);

  final CommerceCheckoutAccepted data;

  Map<String, Object?> toJson() => _$PostChannelsOrdersResponseToJson(this);
}
