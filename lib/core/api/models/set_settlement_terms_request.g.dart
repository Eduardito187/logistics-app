// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_settlement_terms_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetSettlementTermsRequest _$SetSettlementTermsRequestFromJson(
  Map<String, dynamic> json,
) => SetSettlementTermsRequest(
  commissionBasisPoints: (json['commission_basis_points'] as num).toInt(),
  fixedFeeCents: (json['fixed_fee_cents'] as num).toInt(),
  paymentCycle: SetSettlementTermsRequestPaymentCycle.fromJson(
    json['payment_cycle'] as String,
  ),
  currency: json['currency'] as String? ?? 'BOB',
);

Map<String, dynamic> _$SetSettlementTermsRequestToJson(
  SetSettlementTermsRequest instance,
) => <String, dynamic>{
  'commission_basis_points': instance.commissionBasisPoints,
  'fixed_fee_cents': instance.fixedFeeCents,
  'currency': instance.currency,
  'payment_cycle': instance.paymentCycle,
};
