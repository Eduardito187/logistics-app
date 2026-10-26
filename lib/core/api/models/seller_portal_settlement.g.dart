// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalSettlement _$SellerPortalSettlementFromJson(
  Map<String, dynamic> json,
) => SellerPortalSettlement(
  id: json['id'] as String,
  sellerId: json['seller_id'] as String,
  periodFrom: DateTime.parse(json['period_from'] as String),
  periodTo: DateTime.parse(json['period_to'] as String),
  grossCents: (json['gross_cents'] as num).toInt(),
  currency: json['currency'] as String,
  netCents: (json['net_cents'] as num).toInt(),
  status: SellerPortalSettlementStatus.fromJson(json['status'] as String),
  commissionBasisPoints: (json['commission_basis_points'] as num?)?.toInt(),
  commissionCents: (json['commission_cents'] as num?)?.toInt(),
  fixedFeeCents: (json['fixed_fee_cents'] as num?)?.toInt(),
  storageFeeCents: (json['storage_fee_cents'] as num?)?.toInt(),
  fulfillmentFeeCents: (json['fulfillment_fee_cents'] as num?)?.toInt(),
  lastMileFeeCents: (json['last_mile_fee_cents'] as num?)?.toInt(),
  paymentReference: json['payment_reference'] as String?,
);

Map<String, dynamic> _$SellerPortalSettlementToJson(
  SellerPortalSettlement instance,
) => <String, dynamic>{
  'id': instance.id,
  'seller_id': instance.sellerId,
  'period_from': instance.periodFrom.toIso8601String(),
  'period_to': instance.periodTo.toIso8601String(),
  'gross_cents': instance.grossCents,
  'currency': instance.currency,
  'commission_basis_points': instance.commissionBasisPoints,
  'commission_cents': instance.commissionCents,
  'fixed_fee_cents': instance.fixedFeeCents,
  'storage_fee_cents': instance.storageFeeCents,
  'fulfillment_fee_cents': instance.fulfillmentFeeCents,
  'last_mile_fee_cents': instance.lastMileFeeCents,
  'net_cents': instance.netCents,
  'status': instance.status,
  'payment_reference': instance.paymentReference,
};
