// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_payment.dart';

part 'post_channels_payments_response.g.dart';

@JsonSerializable()
class PostChannelsPaymentsResponse {
  const PostChannelsPaymentsResponse({required this.data});

  factory PostChannelsPaymentsResponse.fromJson(Map<String, Object?> json) =>
      _$PostChannelsPaymentsResponseFromJson(json);

  final CommercePayment data;

  Map<String, Object?> toJson() => _$PostChannelsPaymentsResponseToJson(this);
}
