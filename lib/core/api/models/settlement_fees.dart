// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'settlement_fees.g.dart';

@JsonSerializable()
class SettlementFees {
  const SettlementFees({
    required this.commissionBasisPoints,
    required this.commissionCents,
    required this.fixedFeeCents,
    required this.storageFeeCents,
    required this.fulfillmentFeeCents,
    required this.lastMileFeeCents,
    required this.totalCents,
    required this.currency,
  });

  factory SettlementFees.fromJson(Map<String, Object?> json) =>
      _$SettlementFeesFromJson(json);

  @JsonKey(name: 'commission_basis_points')
  final int commissionBasisPoints;
  @JsonKey(name: 'commission_cents')
  final int commissionCents;
  @JsonKey(name: 'fixed_fee_cents')
  final int fixedFeeCents;
  @JsonKey(name: 'storage_fee_cents')
  final int storageFeeCents;
  @JsonKey(name: 'fulfillment_fee_cents')
  final int fulfillmentFeeCents;
  @JsonKey(name: 'last_mile_fee_cents')
  final int lastMileFeeCents;
  @JsonKey(name: 'total_cents')
  final int totalCents;
  final String currency;

  Map<String, Object?> toJson() => _$SettlementFeesToJson(this);
}
