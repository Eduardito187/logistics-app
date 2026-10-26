// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerSettlement _$SellerSettlementFromJson(Map<String, dynamic> json) =>
    SellerSettlement(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String?,
      periodFrom: DateTime.parse(json['period_from'] as String),
      periodTo: DateTime.parse(json['period_to'] as String),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => SettlementLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      grossCents: (json['gross_cents'] as num).toInt(),
      fees: SettlementFees.fromJson(json['fees'] as Map<String, dynamic>),
      netCents: (json['net_cents'] as num).toInt(),
      currency: json['currency'] as String,
      status: SellerSettlementStatus.fromJson(json['status'] as String),
      paymentReference: json['payment_reference'] as String?,
    );

Map<String, dynamic> _$SellerSettlementToJson(SellerSettlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seller_id': instance.sellerId,
      'seller_name': instance.sellerName,
      'period_from': instance.periodFrom.toIso8601String(),
      'period_to': instance.periodTo.toIso8601String(),
      'lines': instance.lines,
      'gross_cents': instance.grossCents,
      'fees': instance.fees,
      'net_cents': instance.netCents,
      'currency': instance.currency,
      'status': instance.status,
      'payment_reference': instance.paymentReference,
    };
