// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Seller _$SellerFromJson(Map<String, dynamic> json) => Seller(
  id: json['id'] as String,
  legalName: json['legal_name'] as String,
  taxId: json['tax_id'] as String,
  status: SellerStatus.fromJson(json['status'] as String),
  contact: SellerContact.fromJson(json['contact'] as Map<String, dynamic>),
  settlementTerms: json['settlement_terms'] == null
      ? null
      : SellerSettlementTerms.fromJson(
          json['settlement_terms'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SellerToJson(Seller instance) => <String, dynamic>{
  'id': instance.id,
  'legal_name': instance.legalName,
  'tax_id': instance.taxId,
  'status': instance.status,
  'contact': instance.contact,
  'settlement_terms': instance.settlementTerms,
};
