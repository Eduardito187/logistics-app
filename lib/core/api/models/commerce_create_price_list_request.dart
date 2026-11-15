// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sales_channel.dart';

part 'commerce_create_price_list_request.g.dart';

@JsonSerializable()
class CommerceCreatePriceListRequest {
  const CommerceCreatePriceListRequest({
    required this.name,
    required this.channel,
    this.currency,
  });

  factory CommerceCreatePriceListRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceCreatePriceListRequestFromJson(json);

  final String name;
  final SalesChannel channel;

  /// ISO 4217; defaults to BOB when omitted.
  final String? currency;

  Map<String, Object?> toJson() => _$CommerceCreatePriceListRequestToJson(this);
}
