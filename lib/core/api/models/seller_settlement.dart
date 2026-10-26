// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_settlement_status.dart';
import 'settlement_fees.dart';
import 'settlement_line.dart';

part 'seller_settlement.g.dart';

@JsonSerializable()
class SellerSettlement {
  const SellerSettlement({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.periodFrom,
    required this.periodTo,
    required this.lines,
    required this.grossCents,
    required this.fees,
    required this.netCents,
    required this.currency,
    required this.status,
    required this.paymentReference,
  });

  factory SellerSettlement.fromJson(Map<String, Object?> json) =>
      _$SellerSettlementFromJson(json);

  final String id;
  @JsonKey(name: 'seller_id')
  final String sellerId;

  /// Readable seller name resolved in the query handler; null if the seller no longer exists.
  @JsonKey(name: 'seller_name')
  final String? sellerName;
  @JsonKey(name: 'period_from')
  final DateTime periodFrom;
  @JsonKey(name: 'period_to')
  final DateTime periodTo;
  final List<SettlementLine> lines;
  @JsonKey(name: 'gross_cents')
  final int grossCents;
  final SettlementFees fees;
  @JsonKey(name: 'net_cents')
  final int netCents;
  final String currency;
  final SellerSettlementStatus status;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;

  Map<String, Object?> toJson() => _$SellerSettlementToJson(this);
}
