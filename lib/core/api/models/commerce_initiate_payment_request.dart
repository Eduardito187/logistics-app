// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_initiate_payment_request.g.dart';

@JsonSerializable()
class CommerceInitiatePaymentRequest {
  const CommerceInitiatePaymentRequest({
    required this.orderId,
    required this.amountCents,
    required this.method,
    this.currency,
  });

  factory CommerceInitiatePaymentRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceInitiatePaymentRequestFromJson(json);

  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'amount_cents')
  final int amountCents;

  /// ISO 4217; defaults to BOB when omitted.
  final String? currency;
  final String method;

  Map<String, Object?> toJson() => _$CommerceInitiatePaymentRequestToJson(this);
}
