// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_contact.dart';
import 'seller_settlement_terms.dart';
import 'seller_status.dart';

part 'seller.g.dart';

@JsonSerializable()
class Seller {
  const Seller({
    required this.id,
    required this.legalName,
    required this.taxId,
    required this.status,
    required this.contact,
    this.settlementTerms,
  });

  factory Seller.fromJson(Map<String, Object?> json) => _$SellerFromJson(json);

  final String id;
  @JsonKey(name: 'legal_name')
  final String legalName;
  @JsonKey(name: 'tax_id')
  final String taxId;
  final SellerStatus status;
  final SellerContact contact;
  @JsonKey(name: 'settlement_terms')
  final SellerSettlementTerms? settlementTerms;

  Map<String, Object?> toJson() => _$SellerToJson(this);
}
