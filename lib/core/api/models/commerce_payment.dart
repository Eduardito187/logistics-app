// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_money.dart';

part 'commerce_payment.g.dart';

@JsonSerializable()
class CommercePayment {
  const CommercePayment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.gatewayRef,
  });

  factory CommercePayment.fromJson(Map<String, Object?> json) =>
      _$CommercePaymentFromJson(json);

  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  final CommerceMoney amount;
  final String method;
  final String status;
  @JsonKey(name: 'gateway_ref')
  final String? gatewayRef;

  Map<String, Object?> toJson() => _$CommercePaymentToJson(this);
}
