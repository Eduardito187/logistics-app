// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'set_settlement_terms_request_payment_cycle.dart';

part 'set_settlement_terms_request.g.dart';

@JsonSerializable()
class SetSettlementTermsRequest {
  const SetSettlementTermsRequest({
    required this.commissionBasisPoints,
    required this.fixedFeeCents,
    required this.paymentCycle,
    this.currency = 'BOB',
  });

  factory SetSettlementTermsRequest.fromJson(Map<String, Object?> json) =>
      _$SetSettlementTermsRequestFromJson(json);

  @JsonKey(name: 'commission_basis_points')
  final int commissionBasisPoints;
  @JsonKey(name: 'fixed_fee_cents')
  final int fixedFeeCents;
  final String currency;
  @JsonKey(name: 'payment_cycle')
  final SetSettlementTermsRequestPaymentCycle paymentCycle;

  Map<String, Object?> toJson() => _$SetSettlementTermsRequestToJson(this);
}
