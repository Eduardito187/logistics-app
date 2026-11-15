// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_order_line.dart';
import 'commerce_ship_to.dart';

part 'commerce_order.g.dart';

@JsonSerializable()
class CommerceOrder {
  const CommerceOrder({
    required this.id,
    required this.status,
    required this.currency,
    required this.totalCents,
    required this.shipmentRequested,
    required this.shipTo,
    required this.lines,
    this.customerId,
  });

  factory CommerceOrder.fromJson(Map<String, Object?> json) =>
      _$CommerceOrderFromJson(json);

  final String id;
  @JsonKey(name: 'customer_id')
  final String? customerId;

  /// Order status (e.g. pending, paid, fulfilling, cancelled).
  final String status;
  final String currency;
  @JsonKey(name: 'total_cents')
  final int totalCents;
  @JsonKey(name: 'shipment_requested')
  final bool shipmentRequested;
  @JsonKey(name: 'ship_to')
  final CommerceShipTo shipTo;
  final List<CommerceOrderLine> lines;

  Map<String, Object?> toJson() => _$CommerceOrderToJson(this);
}
