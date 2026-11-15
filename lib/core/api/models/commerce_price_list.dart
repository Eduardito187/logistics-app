// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_price_list_status.dart';
import 'sales_channel.dart';

part 'commerce_price_list.g.dart';

@JsonSerializable()
class CommercePriceList {
  const CommercePriceList({
    required this.id,
    required this.name,
    required this.currency,
    required this.channel,
    required this.status,
  });

  factory CommercePriceList.fromJson(Map<String, Object?> json) =>
      _$CommercePriceListFromJson(json);

  final String id;
  final String name;
  final String currency;
  final SalesChannel channel;
  final CommercePriceListStatus status;

  Map<String, Object?> toJson() => _$CommercePriceListToJson(this);
}
