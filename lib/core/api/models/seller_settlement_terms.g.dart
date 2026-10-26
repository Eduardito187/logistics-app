// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_settlement_terms.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerSettlementTerms _$SellerSettlementTermsFromJson(
  Map<String, dynamic> json,
) => SellerSettlementTerms(
  commissionBasisPoints: (json['commission_basis_points'] as num).toInt(),
  fixedFee: FixedFee.fromJson(json['fixed_fee'] as Map<String, dynamic>),
  paymentCycle: SellerSettlementTermsPaymentCycle.fromJson(
    json['payment_cycle'] as String,
  ),
);

Map<String, dynamic> _$SellerSettlementTermsToJson(
  SellerSettlementTerms instance,
) => <String, dynamic>{
  'commission_basis_points': instance.commissionBasisPoints,
  'fixed_fee': instance.fixedFee,
  'payment_cycle': instance.paymentCycle,
};
