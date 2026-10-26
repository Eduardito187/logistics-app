// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_fees.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementFees _$SettlementFeesFromJson(Map<String, dynamic> json) =>
    SettlementFees(
      commissionBasisPoints: (json['commission_basis_points'] as num).toInt(),
      commissionCents: (json['commission_cents'] as num).toInt(),
      fixedFeeCents: (json['fixed_fee_cents'] as num).toInt(),
      storageFeeCents: (json['storage_fee_cents'] as num).toInt(),
      fulfillmentFeeCents: (json['fulfillment_fee_cents'] as num).toInt(),
      lastMileFeeCents: (json['last_mile_fee_cents'] as num).toInt(),
      totalCents: (json['total_cents'] as num).toInt(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$SettlementFeesToJson(SettlementFees instance) =>
    <String, dynamic>{
      'commission_basis_points': instance.commissionBasisPoints,
      'commission_cents': instance.commissionCents,
      'fixed_fee_cents': instance.fixedFeeCents,
      'storage_fee_cents': instance.storageFeeCents,
      'fulfillment_fee_cents': instance.fulfillmentFeeCents,
      'last_mile_fee_cents': instance.lastMileFeeCents,
      'total_cents': instance.totalCents,
      'currency': instance.currency,
    };
