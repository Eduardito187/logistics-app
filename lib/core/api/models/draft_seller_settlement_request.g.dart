// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_seller_settlement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftSellerSettlementRequest _$DraftSellerSettlementRequestFromJson(
  Map<String, dynamic> json,
) => DraftSellerSettlementRequest(
  sellerId: json['seller_id'] as String,
  periodFrom: DateTime.parse(json['period_from'] as String),
  periodTo: DateTime.parse(json['period_to'] as String),
  commissionBasisPoints: (json['commission_basis_points'] as num).toInt(),
  fixedFeeCents: (json['fixed_fee_cents'] as num).toInt(),
  currency: json['currency'] as String? ?? 'BOB',
);

Map<String, dynamic> _$DraftSellerSettlementRequestToJson(
  DraftSellerSettlementRequest instance,
) => <String, dynamic>{
  'seller_id': instance.sellerId,
  'period_from': instance.periodFrom.toIso8601String(),
  'period_to': instance.periodTo.toIso8601String(),
  'commission_basis_points': instance.commissionBasisPoints,
  'fixed_fee_cents': instance.fixedFeeCents,
  'currency': instance.currency,
};
