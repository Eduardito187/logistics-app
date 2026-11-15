// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_channels_checkout_response.g.dart';

@JsonSerializable()
class PostChannelsCheckoutResponse {
  const PostChannelsCheckoutResponse({required this.data});

  factory PostChannelsCheckoutResponse.fromJson(Map<String, Object?> json) =>
      _$PostChannelsCheckoutResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() => _$PostChannelsCheckoutResponseToJson(this);
}
