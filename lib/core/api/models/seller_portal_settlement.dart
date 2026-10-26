// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_portal_settlement_status.dart';

part 'seller_portal_settlement.g.dart';

@JsonSerializable()
class SellerPortalSettlement {
  const SellerPortalSettlement({
    required this.id,
    required this.sellerId,
    required this.periodFrom,
    required this.periodTo,
    required this.grossCents,
    required this.currency,
    required this.netCents,
    required this.status,
    this.commissionBasisPoints,
    this.commissionCents,
    this.fixedFeeCents,
    this.storageFeeCents,
    this.fulfillmentFeeCents,
    this.lastMileFeeCents,
    this.paymentReference,
  });

  factory SellerPortalSettlement.fromJson(Map<String, Object?> json) =>
      _$SellerPortalSettlementFromJson(json);

  final String id;
  @JsonKey(name: 'seller_id')
  final String sellerId;
  @JsonKey(name: 'period_from')
  final DateTime periodFrom;
  @JsonKey(name: 'period_to')
  final DateTime periodTo;
  @JsonKey(name: 'gross_cents')
  final int grossCents;
  final String currency;
  @JsonKey(name: 'commission_basis_points')
  final int? commissionBasisPoints;
  @JsonKey(name: 'commission_cents')
  final int? commissionCents;
  @JsonKey(name: 'fixed_fee_cents')
  final int? fixedFeeCents;
  @JsonKey(name: 'storage_fee_cents')
  final int? storageFeeCents;
  @JsonKey(name: 'fulfillment_fee_cents')
  final int? fulfillmentFeeCents;
  @JsonKey(name: 'last_mile_fee_cents')
  final int? lastMileFeeCents;
  @JsonKey(name: 'net_cents')
  final int netCents;
  final SellerPortalSettlementStatus status;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;

  Map<String, Object?> toJson() => _$SellerPortalSettlementToJson(this);
}
