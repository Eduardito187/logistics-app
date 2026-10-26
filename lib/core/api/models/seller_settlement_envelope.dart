// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_settlement.dart';

part 'seller_settlement_envelope.g.dart';

@JsonSerializable()
class SellerSettlementEnvelope {
  const SellerSettlementEnvelope({required this.data});

  factory SellerSettlementEnvelope.fromJson(Map<String, Object?> json) =>
      _$SellerSettlementEnvelopeFromJson(json);

  final SellerSettlement data;

  Map<String, Object?> toJson() => _$SellerSettlementEnvelopeToJson(this);
}
