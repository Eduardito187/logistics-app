// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fixed_fee.dart';
import 'seller_settlement_terms_payment_cycle.dart';

part 'seller_settlement_terms.g.dart';

@JsonSerializable()
class SellerSettlementTerms {
  const SellerSettlementTerms({
    required this.commissionBasisPoints,
    required this.fixedFee,
    required this.paymentCycle,
  });

  factory SellerSettlementTerms.fromJson(Map<String, Object?> json) =>
      _$SellerSettlementTermsFromJson(json);

  /// Commission in basis points (1500 = 15%).
  @JsonKey(name: 'commission_basis_points')
  final int commissionBasisPoints;
  @JsonKey(name: 'fixed_fee')
  final FixedFee fixedFee;
  @JsonKey(name: 'payment_cycle')
  final SellerSettlementTermsPaymentCycle paymentCycle;

  Map<String, Object?> toJson() => _$SellerSettlementTermsToJson(this);
}
