// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_lookup_item.dart';
import 'order_lookup_meta.dart';

part 'order_lookup_response.g.dart';

@JsonSerializable()
class OrderLookupResponse {
  const OrderLookupResponse({required this.data, required this.meta});

  factory OrderLookupResponse.fromJson(Map<String, Object?> json) =>
      _$OrderLookupResponseFromJson(json);

  final List<OrderLookupItem> data;
  final OrderLookupMeta meta;

  Map<String, Object?> toJson() => _$OrderLookupResponseToJson(this);
}
