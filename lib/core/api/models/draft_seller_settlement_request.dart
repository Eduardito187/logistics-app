// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'draft_seller_settlement_request.g.dart';

@JsonSerializable()
class DraftSellerSettlementRequest {
  const DraftSellerSettlementRequest({
    required this.sellerId,
    required this.periodFrom,
    required this.periodTo,
    required this.commissionBasisPoints,
    required this.fixedFeeCents,
    this.currency = 'BOB',
  });

  factory DraftSellerSettlementRequest.fromJson(Map<String, Object?> json) =>
      _$DraftSellerSettlementRequestFromJson(json);

  @JsonKey(name: 'seller_id')
  final String sellerId;
  @JsonKey(name: 'period_from')
  final DateTime periodFrom;
  @JsonKey(name: 'period_to')
  final DateTime periodTo;
  @JsonKey(name: 'commission_basis_points')
  final int commissionBasisPoints;
  @JsonKey(name: 'fixed_fee_cents')
  final int fixedFeeCents;
  final String currency;

  Map<String, Object?> toJson() => _$DraftSellerSettlementRequestToJson(this);
}
